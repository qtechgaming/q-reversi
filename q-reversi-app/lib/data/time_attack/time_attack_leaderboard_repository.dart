import '../../domain/time_attack/time_attack_leaderboard_entry.dart';

abstract class TimeAttackLeaderboardRepository {
  Future<TimeAttackLeaderboardSnapshot> fetchLeaderboard();
}
