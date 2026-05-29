# SpeakMate Mobile — Flutter 手机 App

AI 英语口语陪练的手机端应用，支持 iOS 和 Android。

## 目录结构

```
mobile/
├── pubspec.yaml           # 依赖配置
├── lib/
│   ├── main.dart          # App 入口 + 主题 + 导航
│   ├── api_service.dart   # API 通信层
│   ├── chat_provider.dart # 状态管理（Provider）
│   ├── models.dart        # 数据模型
│   └── screens/
│       ├── scenario_screen.dart  # 场景选择
│       ├── chat_screen.dart      # 聊天界面
│       └── evaluate_screen.dart  # 评分面板
```

## 功能

| 功能 | 说明 |
|------|------|
| 🎭 6 大场景 | 自由/酒店/面试/旅游/商务/雅思 |
| 🎤 语音输入 | 长按麦克风按钮说话 |
| 🔊 TTS 朗读 | AI 回复自动朗读 + 评分标签 |
| 📊 三维评分 | 流利度/语法/词汇 + 改进建议 |
| 🌙 深色主题 | 默认暗色模式 |

## 编译运行

### 前提条件

1. 安装 Flutter SDK：https://flutter.dev/docs/get-started/install
2. 连接手机或开模拟器

### 第一步：后端部署

```bash
# 方案A：本地运行后端（手机同Wi-Fi）
cd ~/speakmate/server
export DEEPSEEK_API_KEY=你的key
~/speakmate/venv/bin/uvicorn main:app --host 0.0.0.0 --port 3001
# 然后修改 api_service.dart 中的 _baseUrl 为电脑的局域网IP

# 方案B：部署到云服务器（推荐）
# 把 server/ 目录传到服务器
pip install fastapi uvicorn httpx pydantic
DEEPSEEK_API_KEY=你的key uvicorn main:app --host 0.0.0.0 --port 80
```

### 第二步：修改 API 地址

编辑 `lib/api_service.dart`，把 `_baseUrl` 改成你的服务器地址：

```dart
// Android 模拟器访问本机
static const String _baseUrl = 'http://10.0.2.2:3001';

// 局域网
static const String _baseUrl = 'http://192.168.1.100:3001';

// 生产服务器
static const String _baseUrl = 'https://speakmate-api.example.com';
```

### 第三步：编译

```bash
cd mobile

# 安装依赖
flutter pub get

# 运行（调试）
flutter run

# 编译 APK（Android）
flutter build apk --release

# 编译 iOS
cd ios && pod install && cd ..
flutter build ios --release
```

## API 配置

手机 App 通过 HTTP API 与后端通信：

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/scenarios` | GET | 场景列表 |
| `/chat` | POST | AI 对话 |
| `/evaluate` | POST | 评分 |
