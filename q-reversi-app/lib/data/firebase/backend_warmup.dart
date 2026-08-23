import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// 放置後のコールドスタートを先に起こす。画面遷移は待たない。
///
/// v2 は関数ごとにインスタンスが分かれるため、実際に使う関数へ warmup を送る。
class BackendWarmup {
  static Future<void>? _inFlight;

  static void kickoff() {
    _inFlight ??= _warm().whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<void> _warm() async {
    try {
      await FirebaseBootstrap.ensureSignedIn();
      await FirebaseBootstrap.waitForAppCheckToken();
      final fn = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      const payload = <String, dynamic>{'warmup': true};
      await Future.wait<void>([
        fn.httpsCallable('startTimeAttackRun').call(payload),
        fn.httpsCallable('submitTimeAttackRun').call(payload),
        fn.httpsCallable('syncVsQuantumWins').call(payload),
        FirebaseFirestore.instance.doc('leaderboards/global').get(),
      ]);
    } catch (e) {
      debugPrint('Backend warmup skipped: $e');
    }
  }
}
