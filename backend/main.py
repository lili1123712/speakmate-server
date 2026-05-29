"""
SpeakMate — FastAPI 主入口
"""

import json
import logging
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from engine import ChatEngine
from scorer import Scorer
from config import SCENARIO_PROMPTS, DATA_DIR

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("speakmate")

app = FastAPI(title="SpeakMate", version="1.0.0")

# CORS — 允许 Electron/Tauri 前端访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = ChatEngine()
scorer = Scorer()


# ─── 数据模型 ───

class ChatRequest(BaseModel):
    messages: list[dict] = Field(..., description="对话历史")
    mode: str = Field(default="free", description="free | scenario")
    scenario: str | None = Field(default=None, description="场景名称")


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


class Scenario(BaseModel):
    id: str
    name: str


class ScenariosResponse(BaseModel):
    scenarios: list[Scenario]


# ─── API ───

@app.get("/scenarios")
def get_scenarios() -> ScenariosResponse:
    """获取可用场景列表"""
    return ScenariosResponse(
        scenarios=[
            Scenario(id=k, name=v["name"])
            for k, v in SCENARIO_PROMPTS.items()
        ]
    )


@app.post("/chat")
def chat(req: ChatRequest) -> ChatResponse:
    """AI 对话"""
    try:
        reply = engine.chat(req.messages, req.mode, req.scenario)
        return ChatResponse(reply=reply)
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/evaluate")
def evaluate(req: EvaluateRequest) -> EvaluateResponse:
    """评估对话表现"""
    try:
        result = scorer.evaluate(req.messages, req.scenario)
        return EvaluateResponse(**result)
    except Exception as e:
        logger.error(f"Evaluate error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    from config import HOST, PORT
    uvicorn.run(app, host=HOST, port=PORT)
