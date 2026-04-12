import 'package:flutter/material.dart';

import '../data/vs_game_persistence_service.dart';
import '../presentation/screens/vs_mode_setup_screen.dart';

/// ルート操作（測定後にモード設定へ確実に遷移するため `MaterialApp` に [key] を渡す）
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// ホームまで戻し、VSモード設定画面を表示。保存済み途中盤は削除。
  static Future<void> exitVsToModeSetup() async {
    await VsGamePersistenceService().clear();
    final nav = key.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const VsModeSetupScreen(),
      ),
    );
  }
}
