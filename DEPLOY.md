# SpeakMate 部署指南

把后端部署到 Railway，手机 App 和桌面版都能用。

## 准备工作

1. 注册 Railway 账号：https://railway.com
2. 安装 Git（已有的话跳过）
3. 准备好 DeepSeek API Key

## 部署步骤（10 分钟）

### 第 1 步：上传代码到 GitHub

```bash
cd ~/speakmate

# 初始化 Git（如果还没有）
git init
git add server/ --force
git commit -m "SpeakMate backend"

# 在 GitHub 创建仓库（网页操作）
# https://github.com/new → 创建 speakmate-server

# 推送到 GitHub
git remote add origin https://github.com/你的用户名/speakmate-server.git
git branch -M main
git push -u origin main
```

### 第 2 步：在 Railway 部署

1. 打开 https://railway.com
2. 点 **New Project** → **Deploy from GitHub repo**
3. 授权 Railway 访问 GitHub
4. 选择刚创建的 `speakmate-server` 仓库
5. 在 Railway Dashboard 点项目 → **Variables** → 添加：
   - Key: `DEEPSEEK_API_KEY`
   - Value: 你的 DeepSeek API Key
6. Railway 会自动检测 Dockerfile 并构建部署
7. 等 2-3 分钟，部署完成后点 **Generate Domain** 获取 URL
8. 你会得到一个类似 `https://speakmate-api.up.railway.app` 的地址

### 第 3 步：验证部署

```bash
# 测试健康检查
curl https://你的域名.up.railway.app/health

# 测试场景列表
curl https://你的域名.up.railway.app/scenarios

# 测试对话
curl -X POST https://你的域名.up.railway.app/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"mode":"free"}'
```

### 第 4 步：更新手机 App

编辑 `mobile/lib/api_service.dart`，把 `_prodUrl` 改成你的 Railway URL：

```dart
static const String _prodUrl = 'https://你的域名.up.railway.app';
```

然后重新编译 APK。

## 费用

Railway 免费额度：
- $5 免费额度/月（足够运行这个小项目）
- 超出后按量计费，约 $0.002/小时
- 不用时会自动休眠

## 更新后端

每次想更新后端：

```bash
cd ~/speakmate
git add server/
git commit -m "更新功能"
git push
```

Railway 会自动重新构建部署，不用手动操作。
