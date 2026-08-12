import 'package:flutter/cupertino.dart';

/// チャレンジレベル間の遷移。
/// [fromRight] が true なら次レベル（右から）、false なら前レベル（左から）。
Route<T> challengeLevelPageRoute<T extends Object?>({
  required WidgetBuilder builder,
  bool fromRight = true,
  RouteSettings? settings,
}) {
  if (fromRight) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
    );
  }

  // 前のレベルへ: 左から入り、現在レベルが右へ抜けていく（iOS の pop に近い）
  return PageRouteBuilder<T>(
    settings: settings,
    opaque: true,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.linearToEaseOut,
        reverseCurve: Curves.easeInToLinear,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
