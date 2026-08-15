import 'package:flutter/foundation.dart';

import '../../domain/vs/vs_quantum_leaderboard_entry.dart';
import 'firestore_vs_quantum_leaderboard_repository.dart';
import 'vs_quantum_leaderboard_repository.dart';

/// 本番は Firestore（入場時 sync）。失敗時は例外を返し、ダミーランキングは出さない。
class DefaultVsQuantumLeaderboardRepository
    implements VsQuantumLeaderboardRepository {
  DefaultVsQuantumLeaderboardRepository({
    VsQuantumLeaderboardRepository? primary,
  }) : _primary = primary ?? FirestoreVsQuantumLeaderboardRepository();

  final VsQuantumLeaderboardRepository _primary;

  @override
  Future<VsQuantumLeaderboardSnapshot> fetchLeaderboard() async {
    try {
      return await _primary.fetchLeaderboard();
    } catch (e, st) {
      debugPrint('VS quantum leaderboard failed: $e\n$st');
      rethrow;
    }
  }
}
