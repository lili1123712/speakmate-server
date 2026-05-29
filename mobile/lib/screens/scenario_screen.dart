import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat_provider.dart';
import '../models.dart';
import 'chat_screen.dart';

class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('选择场景', style: TextStyle(fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),
          body: provider.scenarios.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '选择一个场景开始练习 👇',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: provider.scenarios.length,
                          itemBuilder: (context, i) {
                            final s = provider.scenarios[i];
                            final isActive = provider.currentScenario?.id == s.id;
                            return _ScenarioCard(
                              scenario: s,
                              isActive: isActive,
                              onTap: () {
                                provider.switchScenario(s);
                                // 切换到对话页
                                final home = context.findAncestorStateOfType<_HomePageState>();
                                // 实际项目中用 IndexedStack 或路由
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final bool isActive;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF334155),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(scenario.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              scenario.name,
              style: TextStyle(
                color: isActive ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                scenario.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 引用主文件的 HomePage 类型（实际项目拆到单独文件）
typedef _HomePageState = dynamic;
