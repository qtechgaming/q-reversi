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
    await FirebaseBootstrap.ensureSignedIn();
    if (FirebaseAuth.instance.currentUser == null) {
      throw VsQuantumRemoteException('通信に失敗しました');
    }
  }

  /// ローカル勝利数をサーバーへ同期（増分時のみベスト更新）
  Future<String?> syncWins(int wins) async {
    if (wins < 0) return null;
    await _ensureAuth();
    try {
      final callable = _functions.httpsCallable('syncVsQuantumWins');
      final result = await callable.call(<String, dynamic>{'wins': wins});
      final data = result.data;
      if (data is Map) {
        final displayName = (data['displayName'] as String?)?.trim();
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      return null;
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
