"""
SpeakMate — 对话评分系统
"""

import json
import logging
import re

import httpx

from config import get_deepseek_api_key, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL, SCENARIO_PROMPTS

logger = logging.getLogger("speakmate.scorer")


class Scorer:
    """评估用户对话表现"""

    def __init__(self):
        self.client = httpx.Client(timeout=60)

    def _get_headers(self) -> dict:
        return {
            "Authorization": f"Bearer {get_deepseek_api_key()}",
            "Content-Type": "application/json",
        }

    @staticmethod
    def _parse_json(content: str) -> dict | None:
        """从 LLM 回复中健壮地解析 JSON"""
        # 策略1: 代码块 ```json ... ```
        m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", content, re.DOTALL)
        if m:
            try:
                return json.loads(m.group(1))
            except json.JSONDecodeError:
                pass

        # 策略2: 直接解析整个内容
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            pass

        # 策略3: 找第一个 { 到最后一个 }
        start = content.find("{")
        end = content.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                return json.loads(content[start : end + 1])
            except json.JSONDecodeError:
                pass

        # 策略4: 键值对提取（最坏情况降级）
        result = {
            "score": 0,
            "fluency": 0,
            "grammar": 0,
            "vocabulary": 0,
            "feedback": "Could not parse evaluation.",
            "suggestions": [],
        }

        score_m = re.search(r'"score"\s*:\s*(\d+)', content)
        if score_m:
            result["score"] = min(100, max(0, int(score_m.group(1))))

        for field in ["fluency", "grammar", "vocabulary"]:
            m = re.search(rf'"{field}"\s*:\s*(\d+)', content)
            if m:
                result[field] = min(100, max(0, int(m.group(1))))

        fb_m = re.search(r'"feedback"\s*:\s*"([^"]+)"', content)
        if fb_m:
            result["feedback"] = fb_m.group(1)

        suggs = re.findall(r'"([^"]+)"\s*(?:,|\])', content[content.find("suggestions"):])
        if suggs:
            result["suggestions"] = suggs[:5]

        return result

    @staticmethod
    def _validate_result(result: dict) -> dict:
        """验证并填充缺失字段"""
        defaults = {
            "score": 0,
            "fluency": 0,
            "grammar": 0,
            "vocabulary": 0,
            "feedback": "Evaluation unavailable.",
            "suggestions": [],
        }
        for k, v in defaults.items():
            if k not in result or result[k] is None:
                result[k] = v

        # 确保数值在合理范围
        for field in ["score", "fluency", "grammar", "vocabulary"]:
            try:
                result[field] = min(100, max(0, int(result[field])))
            except (ValueError, TypeError):
                result[field] = 0

        if not isinstance(result["suggestions"], list):
            result["suggestions"] = [str(result["suggestions"])]

        return result

    def evaluate(self, messages: list[dict], scenario: str | None = None) -> dict:
        """评估用户的英语表现"""
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
        user_msg_count = len(user_messages)

        eval_prompt = f"""You are an English language assessment expert. Evaluate the user's English performance in this conversation.

Scenario: {scenario_name}
User messages: {user_msg_count}

Conversation:
{conversation_text}

Provide a detailed evaluation in JSON format with EXACTLY these fields:
{{
    "score": <overall score 1-100>,
    "fluency": <fluency score 1-100>,
    "grammar": <grammar accuracy 1-100>,
    "vocabulary": <vocabulary range and appropriateness 1-100>,
    "feedback": "<2-3 sentence summary of their performance>",
    "suggestions": ["<specific suggestion 1>", "<specific suggestion 2>", "<specific suggestion 3>"]
}}

Return ONLY valid JSON. No markdown formatting."""

        payload = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {"role": "system", "content": "You are a strict but encouraging English teacher. Return ONLY valid JSON."},
                {"role": "user", "content": eval_prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 800,
        }

        try:
            resp = self.client.post(
                f"{DEEPSEEK_BASE_URL}/chat/completions",
                headers=self._get_headers(),
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            content = data["choices"][0]["message"]["content"]

            result = self._parse_json(content)
            if result is None:
                logger.warning(f"Failed to parse evaluation response: {content[:200]}")
                return {
                    "score": 0,
                    "fluency": 0,
                    "grammar": 0,
                    "vocabulary": 0,
                    "feedback": "Could not parse evaluation result.",
                    "suggestions": ["The evaluation service returned an unexpected format. Please try again."],
                }

            return self._validate_result(result)

        except httpx.TimeoutException:
            logger.error("Evaluation request timed out")
            return self._fallback()
        except httpx.HTTPStatusError as e:
            logger.error(f"Evaluation API error: {e.response.status_code} - {e.response.text[:200]}")
            return self._fallback(f"API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Evaluation error: {e}")
            return self._fallback(str(e))

    @staticmethod
    def _fallback(reason: str = "Unknown error") -> dict:
        return {
            "score": 0,
            "fluency": 0,
            "grammar": 0,
            "vocabulary": 0,
            "feedback": f"Evaluation unavailable: {reason}",
            "suggestions": ["Please try again later."],
        }
