import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';
import 'time_attack_run_remote_service.dart';

/// Cloud Functions 経由のプレイヤー名設定
class TimeAttackPlayerRemoteService {
  TimeAttackPlayerRemoteService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseBootstrap.signInAnonymously();
    if (FirebaseAuth.instance.currentUser == null) {
      throw TimeAttackRunRemoteException('通信に失敗しました');
    }
  }

  /// 成功時はサーバー確定の表示名
  Future<String> setPlayerName(String name) async {
    await _ensureAuth();
    try {
      final callable = _functions.httpsCallable('setPlayerName');
      final result = await callable.call(<String, dynamic>{'name': name});
      final data = Map<String, dynamic>.from(result.data as Map);
      final displayName = (data['displayName'] as String?)?.trim();
      if (displayName == null || displayName.isEmpty) {
        throw TimeAttackRunRemoteException('名前の保存に失敗しました');
      }
      return displayName;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        throw TimeAttackRunRemoteException('その名前はすでに使われています');
      }
      if (e.code == 'invalid-argument') {
        throw TimeAttackRunRemoteException(
          e.message?.isNotEmpty == true ? e.message! : '名前が不正です',
        );
      }
      throw TimeAttackRunRemoteException(
        e.message?.isNotEmpty == true ? e.message! : '名前の保存に失敗しました',
      );
    } on TimeAttackRunRemoteException {
      rethrow;
    } catch (_) {
      throw TimeAttackRunRemoteException('名前の保存に失敗しました');
    }
  }
}
