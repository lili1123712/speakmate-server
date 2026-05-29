#!/usr/bin/env bash
# SpeakMate 一键部署脚本
# 你只需要：复制粘贴，按回车执行

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║    SpeakMate 一键部署到 Railway      ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# 第一步：检查 Railway CLI
if ! command -v railway &>/dev/null; then
    echo -e "${YELLOW}📦 安装 Railway CLI...${NC}"
    npm install -g @railway/cli
fi

# 第二步：检查登录
echo -e "\n${YELLOW}🔑 请登录 Railway...${NC}"
echo -e "  1. 打开 https://railway.com/account/tokens"
echo -e "  2. 点 Generate Token → 复制"
echo -e "  3. 粘贴到下面（不显示）\n"
railway login

# 第三步：初始化项目
echo -e "\n${YELLOW}🚀 初始化 Railway 项目...${NC}"
cd "$(dirname "$0")/server"
railway init

# 第四步：设置环境变量
echo -e "\n${YELLOW}🔧 设置 API Key...${NC}"
echo -n "请输入你的 DeepSeek API Key: "
read -s DEEPSEEK_KEY
echo
railway variables set DEEPSEEK_API_KEY="$DEEPSEEK_KEY"

# 第五步：部署
echo -e "\n${YELLOW}📦 部署中（约 2 分钟）...${NC}"
railway up

# 第六步：获取域名
echo -e "\n${GREEN}✅ 部署完成！${NC}"
echo -e "\n${YELLOW}🌐 获取访问域名：${NC}"
railway domain

echo ""
echo -e "${GREEN}部署成功！${NC}"
echo "修改 mobile/lib/api_service.dart 中的 _prodUrl 为你的域名"
echo "然后 flutter build apk --release 编译 APK"
