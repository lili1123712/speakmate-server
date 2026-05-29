"""
SpeakMate — AI 对话引擎
"""

import json
import logging
from typing import Literal

import httpx

from config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL, SCENARIO_PROMPTS

logger = logging.getLogger("speakmate.engine")


class ChatEngine:
    """AI 对话引擎 — 调用 DeepSeek API"""

    def __init__(self):
        self.client = httpx.Client(timeout=60)
        self.headers = {
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
            "Content-Type": "application/json",
        }

    def _get_system_prompt(self, mode: str, scenario: str | None) -> str:
        """根据模式和场景获取系统提示词"""
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

        payload = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                *messages,
            ],
            "temperature": 0.7,
            "max_tokens": 500,
            "stream": False,
        }

        try:
            resp = self.client.post(
                f"{DEEPSEEK_BASE_URL}/chat/completions",
                headers=self.headers,
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            reply = data["choices"][0]["message"]["content"]
            return reply.strip()

        except httpx.HTTPStatusError as e:
            logger.error(f"API error: {e.response.status_code} - {e.response.text[:200]}")
            raise
        except Exception as e:
            logger.error(f"Chat engine error: {e}")
            raise
