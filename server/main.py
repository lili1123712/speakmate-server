"""
SpeakMate — FastAPI 主入口 (云部署版)
支持手机 App 调用，移除本地静态文件依赖
"""

import json
import logging
import os
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from engine import ChatEngine
from scorer import Scorer
from config import get_deepseek_api_key, SCENARIO_PROMPTS, DATA_DIR

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("speakmate")

app = FastAPI(title="SpeakMate API", version="2.0.0")

# CORS — 允许手机 App 和任意前端访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── 启动检查 ───
if not get_deepseek_api_key():
    logger.error("DEEPSEEK_API_KEY is not set!")
    print("⚠️  DEEPSEEK_API_KEY 未设置，API 将返回 503")

# ─── 初始化 ───
engine = ChatEngine()
scorer = Scorer()


# ─── 数据模型 ───

class ChatRequest(BaseModel):
    messages: list[dict] = Field(..., description="对话历史")
    mode: str = Field(default="free", description="free | scenario")
    scenario: str | None = Field(default=None, description="场景ID")


class ChatResponse(BaseModel):
    reply: str
    correction: str | None = None


class EvaluateRequest(BaseModel):
    messages: list[dict] = Field(..., description="完整对话历史")
    scenario: str | None = None


class EvaluateResponse(BaseModel):
    score: float
    fluency: float
    grammar: float
    vocabulary: float
    feedback: str
    suggestions: list[str]


class ScenarioOut(BaseModel):
    id: str
    name: str
    description: str
    icon: str


class TTSRequest(BaseModel):
    text: str


class TTSResponse(BaseModel):
    audio_url: str
    duration_seconds: float = 0


# ─── 静态场景数据（手机 App 直接使用） ───
SCENARIO_META = {
    "free":    {"name": "自由对话", "description": "随心所欲地聊任何话题", "icon": "💬"},
    "hotel":   {"name": "酒店入住", "description": "模拟酒店前台对话", "icon": "🏨"},
    "interview": {"name": "工作面试", "description": "英文技术面试模拟", "icon": "💼"},
    "travel":  {"name": "旅游英语", "description": "出国旅行常用对话", "icon": "✈️"},
    "business": {"name": "商务英语", "description": "会议、谈判、邮件", "icon": "📊"},
    "ielts":   {"name": "雅思口语", "description": "全真模拟雅思口语考试", "icon": "🎯"},
}


# ─── API ───

@app.get("/")
def root():
    return {
        "app": "SpeakMate",
        "version": "2.0.0",
        "platform": "mobile",
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/scenarios")
def get_scenarios():
    """获取场景列表（手机 App 用）"""
    return {
        "scenarios": [
            {"id": k, **v}
            for k, v in SCENARIO_META.items()
        ]
    }


@app.post("/chat")
def chat(req: ChatRequest) -> ChatResponse:
    """AI 对话"""
    if not get_deepseek_api_key():
        raise HTTPException(status_code=503, detail="DEEPSEEK_API_KEY not configured")
    if not req.messages:
        raise HTTPException(status_code=400, detail="No messages provided")

    try:
        reply = engine.chat(req.messages, req.mode, req.scenario)
        return ChatResponse(reply=reply)
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/evaluate")
def evaluate(req: EvaluateRequest) -> EvaluateResponse:
    """对话评分"""
    if not get_deepseek_api_key():
        raise HTTPException(status_code=503, detail="DEEPSEEK_API_KEY not configured")
    if not req.messages:
        raise HTTPException(status_code=400, detail="No messages provided")

    try:
        result = scorer.evaluate(req.messages, req.scenario)
        return EvaluateResponse(**result)
    except Exception as e:
        logger.error(f"Evaluate error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 3001))
    host = os.environ.get("HOST", "0.0.0.0")  # 云部署监听所有网卡
    uvicorn.run(app, host=host, port=port)
