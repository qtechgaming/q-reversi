import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/services/vs_cpu_progress_service.dart';
import 'firebase_bootstrap.dart';
import 'time_attack_pending_submit_store.dart';
import 'time_attack_run_remote_service.dart';

/// ランキング関連データ（クラウド＋端末）の削除
class RankingDataDeletionService {
  RankingDataDeletionService({
    FirebaseFunctions? functions,
    TimeAttackLocalProfileService? profile,
    VsCpuProgressService? vsProgress,
    TimeAttackPendingSubmitStore? pendingStore,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        _profile = profile ?? TimeAttackLocalProfileService(),
        _vsProgress = vsProgress ?? VsCpuProgressService(),
        _pendingStore = pendingStore ?? TimeAttackPendingSubmitStore();

  final FirebaseFunctions _functions;
  final TimeAttackLocalProfileService _profile;
  final VsCpuProgressService _vsProgress;
  final TimeAttackPendingSubmitStore _pendingStore;

  Future<void> deleteAllRankingData() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseBootstrap.ensureSignedIn();
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw TimeAttackRunRemoteException('通信に失敗しました');
    }

    try {
      final callable = _functions.httpsCallable(
        'deleteMyRankingData',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      await callable.call();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('deleteMyRankingData failed: ${e.code} ${e.message}');
      throw TimeAttackRunRemoteException(
        e.message?.isNotEmpty == true
            ? e.message!
            : 'ランキングデータの削除に失敗しました',
      );
    } catch (e) {
      debugPrint('deleteMyRankingData failed: $e');
      throw TimeAttackRunRemoteException('ランキングデータの削除に失敗しました');
    }

    await _clearLocal();
    try {
      await FirebaseBootstrap.signInAnonymously(forceNew: true);
    } catch (e) {
      debugPrint('re-auth after ranking delete failed: $e');
    }
  }

  Future<void> _clearLocal() async {
    await _profile.clearRankingLocalData();
    await _pendingStore.clear();
    await _vsProgress.clearQuantumRankingStats();
  }
}
