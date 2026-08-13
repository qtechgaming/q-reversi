import 'package:flutter/material.dart';

import '../data/vs_game_persistence_service.dart';
import '../presentation/screens/vs_mode_setup_screen.dart';

/// ルート操作（測定後にモード設定へ確実に遷移するため `MaterialApp` に [key] を渡す）
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// VSモード設定画面の [RouteSettings.name]
  ///
  /// 先頭に `/` を付けない（Web で URL に載り、ホットリスタート時に
  /// 「Could not navigate to initial route」になるのを避ける）
  static const String vsSetupRouteName = 'vs_setup';

  /// 対戦画面を閉じ、直下の VS モード設定へ戻る（iOS では右へスワイプアウト）。
  /// 設定がスタックに無い場合のみ新規 push。保存済み途中盤は削除。
  /// 閉じる・戻るのどちらからでも、戻った設定画面で対戦実績を再読込する。
  static Future<void> exitVsToModeSetup() async {
    await VsGamePersistenceService().clear();
    final nav = key.currentState;
    if (nav == null) return;

    var revealedSetup = false;
    nav.popUntil((route) {
      if (route.settings.name == vsSetupRouteName) {
        revealedSetup = true;
        return true;
      }
      return route.isFirst;
    });

    if (!revealedSetup) {
      nav.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: vsSetupRouteName),
          builder: (_) => const VsModeSetupScreen(),
        ),
      );
    } else {
      // 既存の設定画面を再利用しているため、明示的に実績を再読込
      VsModeSetupScreen.requestProgressRefresh();
    }
  }

  /// VS設定画面用ルート（名前付き。閉じる時に下層として残す）
  static Route<void> vsSetupRoute({bool animate = true}) {
    if (!animate) {
      return PageRouteBuilder<void>(
        settings: const RouteSettings(name: vsSetupRouteName),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const VsModeSetupScreen(),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: vsSetupRouteName),
      builder: (_) => const VsModeSetupScreen(),
    );
  }
}
