/// 场景数据模型
class Scenario {
  final String id;
  final String name;
  final String description;
  final String icon;

  const Scenario({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
    );
  }
}

/// 消息模型
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String? correction;
  final int? rating;
  final String? ratingFeedback;

  const ChatMessage({
    required this.role,
    required this.content,
    this.correction,
    this.rating,
    this.ratingFeedback,
  });

  /// 从 AI 回复中解析纠正和评分标记
  factory ChatMessage.ai(String rawContent, {String? correction}) {
    String content = rawContent;
    String? extractedCorrection = correction;

    // 提取 (Correction: ...) 或 (Tip: ...)
    final corrRegExp = RegExp(r'\(*(Correction|Tip):?\s*(.*?)\)', caseSensitive: false);
    final corrMatch = corrRegExp.firstMatch(rawContent);
    if (corrMatch != null && correction == null) {
      extractedCorrection = corrMatch.group(2);
      content = rawContent.replaceFirst(corrMatch.group(0)!, '');
    }

    // 提取 [Rating: X/10 - ...]
    int? rating;
    String? ratingFeedback;
    final ratingRegExp = RegExp(r'\[Rating:\s*(\d+)/10\s*-\s*(.*?)\]');
    final ratingMatch = ratingRegExp.firstMatch(content);
    if (ratingMatch != null) {
      rating = int.tryParse(ratingMatch.group(1)!);
      ratingFeedback = ratingMatch.group(2);
      content = content.replaceFirst(ratingMatch.group(0)!, '');
    }

    return ChatMessage(
      role: 'assistant',
      content: content.trim(),
      correction: extractedCorrection?.trim(),
      rating: rating,
      ratingFeedback: ratingFeedback,
    );
  }

  factory ChatMessage.user(String text) {
    return ChatMessage(role: 'user', content: text);
  }

  Map<String, String> toJson() => {'role': role, 'content': content};
}
