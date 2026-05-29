# SpeakMate Backend
# AI 英语陪练 — 后端核心模块

## 安装

```bash
cd backend
pip install -r requirements.txt
```

## 运行

```bash
uvicorn main:app --reload --port 8000
```

## API

### POST /chat
自由对话

```json
{
  "messages": [{"role": "user", "content": "Hello, how are you?"}],
  "mode": "free",
  "scenario": null
}
```

### POST /chat
场景模拟

```json
{
  "messages": [{"role": "user", "content": "I'd like to book a room"}],
  "mode": "scenario",
  "scenario": "hotel"
}
```

### POST /evaluate
获取对话评分

### POST /transcribe
语音转文字 (Whisper)
