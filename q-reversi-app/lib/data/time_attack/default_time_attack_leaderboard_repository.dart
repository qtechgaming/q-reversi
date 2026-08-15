import 'package:flutter/foundation.dart';

import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import 'firestore_time_attack_leaderboard_repository.dart';
import 'time_attack_leaderboard_repository.dart';

/// 本番は Firestore。失敗時は例外を返し、ダミーランキングは出さない。
class DefaultTimeAttackLeaderboardRepository
    implements TimeAttackLeaderboardRepository {
  DefaultTimeAttackLeaderboardRepository({
    TimeAttackLeaderboardRepository? primary,
  }) : _primary = primary ?? FirestoreTimeAttackLeaderboardRepository();

  final TimeAttackLeaderboardRepository _primary;

  @override
  Future<TimeAttackLeaderboardSnapshot> fetchLeaderboard() async {
    try {
      return await _primary.fetchLeaderboard();
    } catch (e, st) {
      debugPrint('Firestore leaderboard failed: $e\n$st');
      rethrow;
    }
  }
}
