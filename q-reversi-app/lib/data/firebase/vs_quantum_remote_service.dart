import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';

class VsQuantumRemoteException implements Exception {
  final String message;
  VsQuantumRemoteException(this.message);

  @override
  String toString() => message;
}

/// VS量子AIランキング同期（ランキング画面入場時）
class VsQuantumRemoteService {
  VsQuantumRemoteService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseBootstrap.signInAnonymously();
    if (FirebaseAuth.instance.currentUser == null) {
      throw VsQuantumRemoteException('通信に失敗しました');
    }
  }

  /// ローカル勝利数をサーバーへ同期（増分時のみベスト更新）
  Future<void> syncWins(int wins) async {
    if (wins < 0) return;
    await _ensureAuth();
    try {
      final callable = _functions.httpsCallable('syncVsQuantumWins');
      await callable.call(<String, dynamic>{'wins': wins});
    } on FirebaseFunctionsException catch (e) {
      throw VsQuantumRemoteException(
        e.message?.isNotEmpty == true ? e.message! : 'ランキング同期に失敗しました',
      );
    } catch (e) {
      if (e is VsQuantumRemoteException) rethrow;
      throw VsQuantumRemoteException('ランキング同期に失敗しました');
    }
  }
}
