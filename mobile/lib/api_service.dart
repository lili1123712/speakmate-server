import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// SpeakMate API 服务
/// 手机 App 通过此服务与后端通信
class ApiService {
  // 生产服务器地址（部署到 Railway 后替换掉）
  static const String _prodUrl = 'https://speakmate-api.up.railway.app';

  // 本地地址（开发调试用）
  static const String _localUrl = 'http://10.0.2.2:3001';

  // 当前使用的地址（自动选择）
  static String _baseUrl = _prodUrl;

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  /// 设置服务器地址（用户可手动切换）
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// 获取当前服务器地址
  static String get baseUrl => _baseUrl;

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 自动检测可用服务器
  Future<String> detectServer() async {
    // 先试本地
    try {
      final res = await http
          .get(Uri.parse('$_localUrl/health'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        _baseUrl = _localUrl;
        return _localUrl;
      }
    } catch (_) {}

    // 再试生产
    try {
      final res = await http
          .get(Uri.parse('$_prodUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        _baseUrl = _prodUrl;
        return _prodUrl;
      }
    } catch (_) {}

    // 都连不上
    return '';
  }

  /// 获取场景列表
  Future<List<Map<String, dynamic>>> getScenarios() async {
    final res = await http.get(Uri.parse('$_baseUrl/scenarios'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Map<String, dynamic>>.from(data['scenarios']);
    }
    throw Exception('Failed to load scenarios: ${res.statusCode}');
  }

  /// 对话
  Future<Map<String, dynamic>> chat({
    required List<Map<String, String>> messages,
    String mode = 'free',
    String? scenario,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'messages': messages,
        'mode': mode,
        'scenario': scenario,
      }),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Chat API error: ${res.statusCode} ${res.body}');
  }

  /// 评分
  Future<Map<String, dynamic>> evaluate({
    required List<Map<String, String>> messages,
    String? scenario,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'messages': messages,
        'scenario': scenario,
      }),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Evaluate API error: ${res.statusCode} ${res.body}');
  }
}
