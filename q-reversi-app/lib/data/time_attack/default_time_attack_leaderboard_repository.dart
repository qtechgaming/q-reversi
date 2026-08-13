import 'package:flutter/foundation.dart';

import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import 'fake_time_attack_leaderboard_repository.dart';
import 'firestore_time_attack_leaderboard_repository.dart';
import 'time_attack_leaderboard_repository.dart';

/// 本番は Firestore。失敗時（または明示デバッグ）は Fake にフォールバック。
class DefaultTimeAttackLeaderboardRepository
    implements TimeAttackLeaderboardRepository {
  DefaultTimeAttackLeaderboardRepository({
    TimeAttackLeaderboardRepository? primary,
    TimeAttackLeaderboardRepository? fallback,
    bool? useFakeOnly,
  })  : _primary = primary ?? FirestoreTimeAttackLeaderboardRepository(),
        _fallback = fallback ?? FakeTimeAttackLeaderboardRepository(),
        _useFakeOnly = useFakeOnly ?? false;

  final TimeAttackLeaderboardRepository _primary;
  final TimeAttackLeaderboardRepository _fallback;
  final bool _useFakeOnly;

  /// Firestore / App Check が返ってこない場合にスピナー固定になるのを防ぐ
  static const _fetchTimeout = Duration(seconds: 12);

  @override
  Future<TimeAttackLeaderboardSnapshot> fetchLeaderboard() async {
    if (_useFakeOnly) {
      return _fallback.fetchLeaderboard();
    }
    try {
      return await _primary.fetchLeaderboard().timeout(_fetchTimeout);
    } catch (e, st) {
      debugPrint('Firestore leaderboard failed, fallback to fake: $e\n$st');
      return _fallback.fetchLeaderboard();
    }
  }
}
