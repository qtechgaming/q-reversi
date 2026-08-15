import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';
import 'firestore_get_with_retry.dart';
import 'time_attack_run_remote_service.dart';

/// Cloud Functions / Firestore 経由のプレイヤー名
class TimeAttackPlayerRemoteService {
  TimeAttackPlayerRemoteService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> _ensureAuth() async {
    await FirebaseBootstrap.ensureSignedIn();
    if (FirebaseAuth.instance.currentUser == null) {
      throw TimeAttackRunRemoteException('通信に失敗しました');
    }
  }

  /// `users/{uid}.displayName`。未設定・失敗時は null
  Future<String?> fetchDisplayName() async {
    try {
      await _ensureAuth();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final snap = await FirestoreGetWithRetry.getDoc(
        _firestore,
        'users/$uid',
        attempts: 2,
      );
      final name = (snap.data()?['displayName'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;
      return name;
    } catch (_) {
      return null;
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
