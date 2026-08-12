import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_progress_notifier.dart';
import 'challenge_level_selection_screen.dart';

/// レベル選択が「本当にゲーム終了して戻ってきた」ことを待つためのセッション。
/// 同一ステージの pushReplacement（次へ / スワイプ）では [finish] しない。
class ChallengePlaySession {
  Completer<Object?>? _completer;

  Future<Object?> arm() {
    _completer = Completer<Object?>();
    return _completer!.future;
  }

  void finish([Object? result]) {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }
}

/// チャレンジモード専用の [Navigator] と [ChallengeProgressNotifier] をまとめたスコープ。
/// レベル選択・ゲームが同じ Notifier を共有する（「次へ」でも Provider が切れない）。
class ChallengeFlowScope extends StatelessWidget {
  const ChallengeFlowScope({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChallengeProgressNotifier()),
        Provider(create: (_) => ChallengePlaySession()),
      ],
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
