import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat_provider.dart';
import '../models.dart';
import 'evaluate_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final scenarioName = provider.currentScenario?.name ?? '自由对话';
        final scenarioIcon = provider.currentScenario?.icon ?? '💬';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(scenarioIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(scenarioName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              // 评分按钮
              if (provider.messages.where((m) => m.role == 'user').length >= 2)
                IconButton(
                  icon: const Icon(Icons.leaderboard_outlined),
                  tooltip: '评分',
                  onPressed: () async {
                    final result = await provider.evaluate();
                    if (result != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EvaluateScreen(result: result),
                        ),
                      );
                    }
                  },
                ),
              // 自动朗读开关
              IconButton(
                icon: Icon(
                  provider.autoSpeak ? Icons.volume_up : Icons.volume_off,
                  color: provider.autoSpeak ? null : const Color(0xFF64748B),
                ),
                tooltip: '自动朗读',
                onPressed: provider.toggleAutoSpeak,
              ),
            ],
          ),
          body: Column(
            children: [
              // 错误提示
              if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF7F1D1D),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: provider.clearError,
                        child: const Icon(Icons.close, color: Color(0xFFFCA5A5), size: 18),
                      ),
                    ],
                  ),
                ),
              // 消息列表
              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState(scenarioName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, i) {
                          final msg = provider.messages[i];
                          return _MessageBubble(message: msg);
                        },
                      ),
              ),
              // 加载指示器
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              // 输入区
              _buildInputArea(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String scenarioName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗣️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '当前场景: $scenarioName',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在下方输入框开始英语对话\nAI 会实时纠正你的语法错误 ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          // 语音输入按钮
          GestureDetector(
            onLongPress: () => provider.startListening(),
            onLongPressUp: () => provider.stopListening(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.isListening
                    ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: provider.isListening ? const Color(0xFFEF4444) : const Color(0xFF334155),
                  width: 2,
                ),
              ),
              child: Icon(
                provider.isListening ? Icons.mic : Icons.mic_none,
                color: provider.isListening ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 输入框
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !provider.isLoading,
              decoration: InputDecoration(
                hintText: provider.isListening ? '🎤 正在听...' : '用英语输入...',
                hintStyle: TextStyle(
                  color: provider.isListening ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  provider.sendMessage(text);
                  _inputCtrl.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          GestureDetector(
            onTap: () {
              final text = _inputCtrl.text;
              if (text.trim().isNotEmpty && !provider.isLoading) {
                provider.sendMessage(text);
                _inputCtrl.clear();
              }
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: provider.isLoading
                    ? const Color(0xFF334155)
                    : const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF22D3EE),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  // 评分标签
                  if (message.rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⭐ ${message.rating}/10${message.ratingFeedback != null ? ' — ${message.ratingFeedback}' : ''}',
                          style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 12),
                        ),
                      ),
                    ),
                  // 纠正提示
                  if (message.correction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💡 ${message.correction}',
                          style: const TextStyle(color: Color(0xFFEAB308), fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('👤', style: TextStyle(fontSize: 16))),
            ),
          ],
        ],
      ),
    );
  }
}
