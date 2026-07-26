import '../../domain/entities/challenge_level.dart';

/// 同一ステージ内の「次へ」で、選択画面経由で次レベルへ進む結果
class ChallengeContinueToLevelResult {
  final ChallengeLevel level;

  const ChallengeContinueToLevelResult(this.level);
}

/// ステージ最終クリア後の「次へ」で、選択画面経由で次ステージ先頭へ進む結果
class ChallengeStageAdvanceResult {
  final int completedStageNumber;
  final int nextStageNumber;
  final ChallengeLevel firstLevel;

  const ChallengeStageAdvanceResult({
    required this.completedStageNumber,
    required this.nextStageNumber,
    required this.firstLevel,
  });
}
