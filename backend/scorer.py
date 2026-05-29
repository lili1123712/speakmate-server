"""
SpeakMate — 对话评分系统
"""

import json
import logging
import re

import httpx

from config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL, SCENARIO_PROMPTS

logger = logging.getLogger("speakmate.scorer")


class Scorer:
    """评估用户对话表现"""

    def __init__(self):
        self.client = httpx.Client(timeout=60)
        self.headers = {
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
            "Content-Type": "application/json",
        }

    def evaluate(self, messages: list[dict], scenario: str | None = None) -> dict:
        """评估用户的英语表现"""
        # 提取用户的发言
        user_messages = [m["content"] for m in messages if m["role"] == "user"]
        if not user_messages:
            return {
                "score": 0,
                "fluency": 0,
                "grammar": 0,
                "vocabulary": 0,
                "feedback": "No conversation data to evaluate.",
                "suggestions": ["Start a conversation first!"],
            }

        conversation_text = "\n".join(
            f"{'User' if m['role'] == 'user' else 'AI'}: {m['content']}"
            for m in messages
        )

        scenario_name = SCENARIO_PROMPTS.get(scenario or "", {}).get("name", "General")

        eval_prompt = f"""You are an English language assessment expert. Evaluate the user's English performance in this conversation.

Scenario: {scenario_name}

Conversation:
{conversation_text}

Provide a detailed evaluation in JSON format with EXACTLY these fields:
```json
{{
    "score": <overall score 1-100>,
    "fluency": <fluency score 1-100>,
    "grammar": <grammar accuracy 1-100>,
    "vocabulary": <vocabulary range and appropriateness 1-100>,
    "feedback": "<2-3 sentence summary of their performance>",
    "suggestions": ["<specific suggestion 1>", "<specific suggestion 2>", "<specific suggestion 3>"]
}}
```

Be honest but encouraging. Focus on patterns, not individual mistakes.
If there's very little data to evaluate, note that in suggestions."""

        payload = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {"role": "system", "content": "You are a strict but encouraging English teacher."},
                {"role": "user", "content": eval_prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 800,
        }

        try:
            resp = self.client.post(
                f"{DEEPSEEK_BASE_URL}/chat/completions",
                headers=self.headers,
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            content = data["choices"][0]["message"]["content"]

            # 解析 JSON
            json_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", content, re.DOTALL)
            if json_match:
                result = json.loads(json_match.group(1))
            else:
                # 尝试直接解析
                result = json.loads(content)

            # 验证必要字段
            required = ["score", "fluency", "grammar", "vocabulary", "feedback", "suggestions"]
            for field in required:
                if field not in result:
                    result[field] = 0 if field != "feedback" and field != "suggestions" else (
                        "Evaluation unavailable" if field == "feedback" else []
                    )

            return result

        except Exception as e:
            logger.error(f"Evaluation error: {e}")
            return {
                "score": 0,
                "fluency": 0,
                "grammar": 0,
                "vocabulary": 0,
                "feedback": f"Could not complete evaluation: {str(e)}",
                "suggestions": ["Try again later."],
            }
