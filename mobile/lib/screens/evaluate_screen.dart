import 'package:flutter/material.dart';

class EvaluateScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const EvaluateScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final score = _num(result['score']);
    final fluency = _num(result['fluency']);
    final grammar = _num(result['grammar']);
    final vocabulary = _num(result['vocabulary']);
    final feedback = result['feedback'] as String? ?? '';
    final suggestions = (result['suggestions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('对话评估', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 总分
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
                    ),
                  ),
                  const Text(
                    '综合评分',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 三维评分
            Row(
              children: [
                _ScoreItem(label: '流利度', value: fluency, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                _ScoreItem(label: '语法', value: grammar, color: const Color(0xFF22C55E)),
                const SizedBox(width: 12),
                _ScoreItem(label: '词汇', value: vocabulary, color: const Color(0xFFEAB308)),
              ],
            ),
            const SizedBox(height: 24),
            // 评价
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 评价',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feedback,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 改进建议
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 改进建议',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFFEAB308))),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (suggestions.isEmpty)
                    const Text(
                      '暂无建议，继续对话吧',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _num(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return 0;
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value / 100.0,
                backgroundColor: const Color(0xFF334155),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
