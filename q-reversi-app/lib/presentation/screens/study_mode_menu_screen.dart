import 'package:flutter/material.dart';
import '../../domain/entities/game_mode.dart';
import 'study_quantum_intro_screen.dart';
import 'study_one_cell_quantum_screen.dart';
import 'study_two_cell_quantum_screen.dart';
import 'study_three_cell_grover_screen.dart';
import 'study_epilogue_screen.dart';

/// スタディモード: 学習コンテンツ一覧
class StudyModeMenuScreen extends StatelessWidget {
  const StudyModeMenuScreen({super.key});

  static const List<_StudyMenuItem> _items = [
    _StudyMenuItem(
      mode: StudyMode.intro,
      title: '量子コンピュータとは？',
      icon: Icons.lightbulb_outline,
    ),
    _StudyMenuItem(
      mode: StudyMode.study1,
      title: '1マスで学ぶ\n量子コンピュータ',
      icon: Icons.looks_one,
    ),
    _StudyMenuItem(
      mode: StudyMode.study2,
      title: '2マスで学ぶ\n量子コンピュータ',
      icon: Icons.looks_two,
    ),
    _StudyMenuItem(
      mode: StudyMode.study3,
      title: '3マスで学ぶ\nグローバーのアルゴリズム',
      icon: Icons.auto_graph,
    ),
    _StudyMenuItem(
      mode: StudyMode.epilogue,
      title: '終わりに',
      icon: Icons.menu_book,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'スタディモード',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _StudyMenuCard(
                item: item,
                onTap: () {
                  if (item.mode == StudyMode.intro) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyQuantumIntroScreen(),
                      ),
                    );
                    return;
                  }
                  if (item.mode == StudyMode.study1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyOneCellQuantumScreen(),
                      ),
                    );
                    return;
                  }
                  if (item.mode == StudyMode.study2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyTwoCellQuantumScreen(),
                      ),
                    );
                    return;
                  }
                  if (item.mode == StudyMode.study3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyThreeCellGroverScreen(),
                      ),
                    );
                    return;
                  }
                  if (item.mode == StudyMode.epilogue) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyEpilogueScreen(),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('画面遷移に失敗しました'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudyMenuItem {
  const _StudyMenuItem({
    required this.mode,
    required this.title,
    required this.icon,
  });

  final StudyMode mode;
  final String title;
  final IconData icon;
}

class _StudyMenuCard extends StatelessWidget {
  const _StudyMenuCard({
    required this.item,
    required this.onTap,
  });

  final _StudyMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1F3A).withValues(alpha: 0.85),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 32,
          color: const Color(0xFF6B46C1),
        ),
        title: Text(
          item.title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(
          Icons.arrow_forward,
          color: Colors.white70,
        ),
        onTap: onTap,
      ),
    );
  }
}
