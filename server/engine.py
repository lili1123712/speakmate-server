"""
SpeakMate — AI 对话引擎
"""

import json
import logging

import httpx

from config import get_deepseek_api_key, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL, SCENARIO_PROMPTS

logger = logging.getLogger("speakmate.engine")


class ChatEngine:
    """AI 对话引擎 — 调用 DeepSeek API"""

    def __init__(self):
        self.client = httpx.Client(timeout=60)

    def _get_headers(self) -> dict:
        api_key = get_deepseek_api_key()
        if not api_key:
            raise ValueError("DEEPSEEK_API_KEY is not set")
        return {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

    def _get_system_prompt(self, mode: str, scenario: str | None) -> str:
        if mode == "free":
            return SCENARIO_PROMPTS["free"]["system"]

        if scenario and scenario in SCENARIO_PROMPTS:
            return SCENARIO_PROMPTS[scenario]["system"]

        return SCENARIO_PROMPTS["free"]["system"]

    def chat(
        self,
        messages: list[dict],
        mode: str = "free",
        scenario: str | None = None,
    ) -> str:
        """发送消息给 AI 并获取回复"""
        system_prompt = self._get_system_prompt(mode, scenario)

        # 限制历史消息数量防止 token 超限
        recent_messages = messages[-20:] if len(messages) > 20 else messages

        payload = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                *recent_messages,
            ],
            "temperature": 0.7,
            "max_tokens": 500,
            "stream": False,
        }

        try:
            resp = self.client.post(
                f"{DEEPSEEK_BASE_URL}/chat/completions",
                headers=self._get_headers(),
                json=payload,
                timeout=60,
            )
            resp.raise_for_status()
            data = resp.json()

            # 验证响应结构
            if "choices" not in data or not data["choices"]:
                logger.error(f"Unexpected API response: {data}")
                return "Sorry, I received an unexpected response. Could you try again?"

            reply = data["choices"][0]["message"]["content"]
            if not reply or not reply.strip():
                return "I'm not sure what to say. Could you rephrase that?"

            return reply.strip()

        except httpx.TimeoutException:
            logger.error("API request timed out")
            return "Sorry, the request timed out. Could you please try again?"
        except httpx.HTTPStatusError as e:
            status = e.response.status_code
            if status == 401:
                logger.error("API authentication failed")
                return "Sorry, there's an authentication issue with the AI service. Please check your API key."
            elif status == 429:
                logger.error("API rate limited")
                return "Sorry, I'm receiving too many requests right now. Please wait a moment and try again."
            elif status == 503:
                logger.error("API service unavailable")
                return "Sorry, the AI service is temporarily unavailable. Please try again later."
            else:
                logger.error(f"API error: {status} - {e.response.text[:200]}")
                return f"Sorry, an error occurred (HTTP {status}). Please try again."
        except ValueError as e:
            if "API_KEY" in str(e):
                return "API key is not configured. Please set the DEEPSEEK_API_KEY environment variable."
            logger.error(f"Value error: {e}")
            return "Sorry, there's a configuration issue. Please check your setup."
        except Exception as e:
            logger.error(f"Chat engine error: {e}")
            return "Sorry, something went wrong. Please try again."
