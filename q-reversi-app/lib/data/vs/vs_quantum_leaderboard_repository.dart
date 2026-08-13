import '../../domain/vs/vs_quantum_leaderboard_entry.dart';

abstract class VsQuantumLeaderboardRepository {
  Future<VsQuantumLeaderboardSnapshot> fetchLeaderboard();
}
