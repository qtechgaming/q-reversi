import 'package:flutter/foundation.dart';

import '../../domain/vs/vs_quantum_leaderboard_entry.dart';
import 'fake_vs_quantum_leaderboard_repository.dart';
import 'firestore_vs_quantum_leaderboard_repository.dart';
import 'vs_quantum_leaderboard_repository.dart';

/// 本番は Firestore（入場時 sync）。失敗時は Fake にフォールバック。
class DefaultVsQuantumLeaderboardRepository
    implements VsQuantumLeaderboardRepository {
  DefaultVsQuantumLeaderboardRepository({
    VsQuantumLeaderboardRepository? primary,
    VsQuantumLeaderboardRepository? fallback,
    bool? useFakeOnly,
  })  : _primary = primary ?? FirestoreVsQuantumLeaderboardRepository(),
        _fallback = fallback ?? FakeVsQuantumLeaderboardRepository(),
        _useFakeOnly = useFakeOnly ?? false;

  final VsQuantumLeaderboardRepository _primary;
  final VsQuantumLeaderboardRepository _fallback;
  final bool _useFakeOnly;

  /// sync / Firestore がハングしたときにスピナー固定になるのを防ぐ
  static const _fetchTimeout = Duration(seconds: 12);

  @override
  Future<VsQuantumLeaderboardSnapshot> fetchLeaderboard() async {
    if (_useFakeOnly) {
      return _fallback.fetchLeaderboard();
    }
    try {
      return await _primary.fetchLeaderboard().timeout(_fetchTimeout);
    } catch (e, st) {
      debugPrint('VS quantum leaderboard failed, fallback to fake: $e\n$st');
      return _fallback.fetchLeaderboard();
    }
  }
}
