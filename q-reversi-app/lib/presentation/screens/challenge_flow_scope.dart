import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_progress_notifier.dart';
import 'challenge_level_selection_screen.dart';

/// チャレンジモード専用の [Navigator] と [ChallengeProgressNotifier] をまとめたスコープ。
/// レベル選択・ゲームが同じ Notifier を共有する（「次へ」でも Provider が切れない）。
class ChallengeFlowScope extends StatelessWidget {
  const ChallengeFlowScope({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChallengeProgressNotifier(),
      child: const Navigator(
        initialRoute: _selectionRoute,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static const String _selectionRoute = '/';

  static Route<void> _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const ChallengeLevelSelectionScreen(),
    );
  }
}
