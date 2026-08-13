import 'package:flutter/foundation.dart';

import 'time_attack_pending_submit_store.dart';
import 'time_attack_run_remote_service.dart';

/// 起動時などに pending submit を再送する
class TimeAttackPendingSubmitRetry {
  TimeAttackPendingSubmitRetry({
    TimeAttackPendingSubmitStore? store,
    TimeAttackRunRemoteService? remote,
  })  : _store = store ?? TimeAttackPendingSubmitStore(),
        _remote = remote ?? TimeAttackRunRemoteService();

  final TimeAttackPendingSubmitStore _store;
  final TimeAttackRunRemoteService _remote;

  /// 成功時 true。pending なし / 失敗時 false（失敗時は pending を残す）
  Future<bool> tryFlush() async {
    final pending = await _store.load();
    if (pending == null) return false;

    try {
      await _remote.submitRun(
        runId: pending.runId,
        levelResults: pending.levelResults,
      );
      await _store.clear();
      debugPrint(
        'TIME ATTACK pending submit を再送しました (runId=${pending.runId})',
      );
      return true;
    } catch (e, st) {
      debugPrint('TIME ATTACK pending submit 再送失敗: $e\n$st');
      return false;
    }
  }
}
