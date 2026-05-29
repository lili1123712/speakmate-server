import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'api_service.dart';
import 'models.dart';

/// 聊天页面状态管理
class ChatProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<ChatMessage> _messages = [];
  List<Scenario> _scenarios = [];
  Scenario? _currentScenario;
  bool _isLoading = false;
  bool _isListening = false;
  bool _autoSpeak = true;
  String? _error;

  // Getters
  List<ChatMessage> get messages => _messages;
  List<Scenario> get scenarios => _scenarios;
  Scenario? get currentScenario => _currentScenario;
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  bool get autoSpeak => _autoSpeak;
  String? get error => _error;

  // 语音
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  ChatProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  /// 加载场景
  Future<void> loadScenarios() async {
    try {
      _scenarios = (await _api.getScenarios())
          .map((s) => Scenario.fromJson(s))
          .toList();
      if (_scenarios.isNotEmpty) {
        _currentScenario = _scenarios.first;
      }
      notifyListeners();
    } catch (e) {
      _error = '无法加载场景: $e';
      notifyListeners();
    }
  }

  /// 切换场景
  void switchScenario(Scenario s) {
    _currentScenario = s;
    _messages = [];
    // 添加 AI 开场白
    _messages.add(ChatMessage.ai(_getOpening(s.id)));
    notifyListeners();
  }

  String _getOpening(String id) {
    final openings = {
      'free': "Hello there! I'm SpeakMate, your English conversation partner. How are you doing today?",
      'hotel': "Good evening! Welcome to our hotel. How may I assist you today?",
      'interview': "Good morning, I'm Sarah from HR. Why don't you start by telling me a little bit about yourself?",
      'travel': "Welcome to London! I'm your local guide. What kind of places are you interested in visiting?",
      'business': "Good morning! How was your weekend? I was looking at the Q3 projections and wanted to discuss some ideas.",
      'ielts': "Hello, I'm your IELTS speaking examiner. Let's begin with Part 1. Could you tell me about where you live?",
    };
    return openings[id] ?? openings['free']!;
  }

  /// 发送消息
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messages.add(ChatMessage.user(text.trim()));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.chat(
        messages: _messages.map((m) => m.toJson()).toList(),
        scenario: _currentScenario?.id,
      );
      final reply = ChatMessage.ai(res['reply'] as String);
      _messages.add(reply);
      _isLoading = false;
      notifyListeners();

      // 自动朗读
      if (_autoSpeak) {
        await _tts.speak(reply.content);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 评分
  Future<Map<String, dynamic>?> evaluate() async {
    if (_messages.isEmpty) return null;
    try {
      return await _api.evaluate(
        messages: _messages.map((m) => m.toJson()).toList(),
        scenario: _currentScenario?.id,
      );
    } catch (e) {
      _error = '评分失败: $e';
      notifyListeners();
      return null;
    }
  }

  /// 语音输入
  Future<void> startListening() async {
    final available = await _speech.initialize();
    if (!available) {
      _error = '语音识别不可用';
      notifyListeners();
      return;
    }
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            sendMessage(text);
          }
          stopListening();
        }
      },
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
    );
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  void toggleAutoSpeak() {
    _autoSpeak = !_autoSpeak;
    notifyListeners();
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
