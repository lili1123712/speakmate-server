#!/usr/bin/env bash
# SpeakMate — 一键启动脚本
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
SERVER_DIR="$SCRIPT_DIR/server"
APP_FILE="$SCRIPT_DIR/app/index.html"

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║        SpeakMate 启动器              ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# ─── 检查 API Key ───
API_KEY=""
if [ -n "$DEEPSEEK_API_KEY" ]; then
    API_KEY="$DEEPSEEK_API_KEY"
elif [ -f "$HOME/.hermes/.env" ]; then
    API_KEY=$(python3 -c "
import re
try:
    with open('$HOME/.hermes/.env') as f:
        m = re.search(r'DEEPSEEK_API_KEY=(.+)', f.read())
        if m: print(m.group(1).strip())
except: pass
" 2>/dev/null)
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ DEEPSEEK_API_KEY 未设置${NC}"
    echo ""
    echo "  请设置环境变量："
    echo -e "  ${YELLOW}export DEEPSEEK_API_KEY=你的key${NC}"
    echo "  或将 key 写入 ~/.hermes/.env："
    echo -e "  ${YELLOW}echo 'DEEPSEEK_API_KEY=你的key' >> ~/.hermes/.env${NC}"
    echo ""
    exit 1
fi

echo -e "  ${GREEN}✓${NC} API Key 已找到"

# ─── 安装依赖 ───
if [ ! -f "$VENV_DIR/bin/uvicorn" ]; then
    echo -e "  ${YELLOW}📦${NC} 首次运行，正在安装依赖..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install fastapi uvicorn httpx pydantic python-multipart -q
    echo -e "  ${GREEN}✓${NC} 依赖安装完成"
fi

# ─── 杀死旧进程 ───
OLD_PID=$(lsof -ti:3001 2>/dev/null || true)
if [ -n "$OLD_PID" ]; then
    echo -e "  ${YELLOW}♻️${NC} 关闭旧进程 (PID: $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 1
fi

# ─── 启动后端 ───
echo -e "  ${GREEN}🚀${NC} 启动 SpeakMate 服务..."
export DEEPSEEK_API_KEY="$API_KEY"
"$VENV_DIR/bin/uvicorn" main:app --host 127.0.0.1 --port 3001 &
SERVER_PID=$!

# 等待后端就绪
echo -n "  ⏳ 等待后端就绪"
for i in $(seq 1 10); do
    if curl -s http://127.0.0.1:3001/health >/dev/null 2>&1; then
        echo ""
        echo -e "  ${GREEN}✓${NC} 后端已就绪"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "  ${CYAN}📍${NC} 后端地址: http://127.0.0.1:3001"
echo -e "  ${CYAN}📍${NC} 前端文件: $APP_FILE"
echo ""
echo -e "  ${YELLOW}💡${NC} 在浏览器中打开前端文件即可使用"
echo -e "  ${YELLOW}💡${NC} 按 Ctrl+C 停止服务"
echo ""

# ─── 打开前端 ───
if [ -f "$APP_FILE" ]; then
    if command -v xdg-open &>/dev/null; then
        xdg-open "$APP_FILE" 2>/dev/null || true
    elif command -v open &>/dev/null; then
        open "$APP_FILE" 2>/dev/null || true
    elif command -v wslview &>/dev/null; then
        wslview "$APP_FILE" 2>/dev/null || true
    fi
fi

# ─── 等待退出信号 ───
trap "echo ''; echo -e '  ${YELLOW}👋${NC} 正在关闭...'; kill $SERVER_PID 2>/dev/null; exit 0" INT TERM
wait $SERVER_PID
