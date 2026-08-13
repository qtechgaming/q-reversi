import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_navigator.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'data/firebase/time_attack_pending_submit_retry.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseBootstrap.initialize();
    FirebaseBootstrap.logInitResult();
    // 起動をブロックしすぎないよう、pending 再送は待たずに走らせる
    unawaited(TimeAttackPendingSubmitRetry().tryFlush());
  } catch (e, st) {
    debugPrint('Firebase 初期化に失敗しました: $e\n$st');
  }
  runApp(const QReversiApp());
}

class QReversiApp extends StatelessWidget {
  const QReversiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      title: 'Q-Reversi',
      theme: AppTheme.darkTheme,
      // Web のアドレスバーに残った深いパスを初期ルートにしない
      initialRoute: '/',
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
