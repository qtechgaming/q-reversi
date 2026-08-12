import '../entities/challenge_level.dart';
import 'time_attack_config.dart';

class TimeAttackScoreResolver {
  const TimeAttackScoreResolver();

  int score({
    required int optimalTurns,
    required int difficulty,
  }) =>
      optimalTurns + difficulty;

  int scoreForLevel(ChallengeLevel level) => level.timeAttackScore;

  int tierForQuestionIndex(int index) =>
      TimeAttackConfig.tierForQuestionIndex(index);
}
