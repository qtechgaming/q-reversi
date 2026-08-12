/// TIME ATTACK 調整パラメータ（1か所に集約）
class TimeAttackConfig {
  static const int configVersion = 1;

  static const int totalLevels = 50;

  static const Duration initialTime = Duration(seconds: 30);
  static const Duration maxTime = Duration(seconds: 60);

  /// Combo Bonus = currentCombo × comboPointStep
  static const int comboPointStep = 10;

  /// CLEAR BONUS = clearCount × clearBonusPerClear
  static const int clearBonusPerClear = 1000;

  /// 残り時間ボーナス: 0.1秒 = 10 points
  static const int timeBonusUnitMs = 100;
  static const int timeBonusPointsPerUnit = 10;

  static const Duration uiTickInterval = Duration(milliseconds: 50);

  /// CLEAR 演出の最低表示時間（この間は TIMER を止める）
  static const Duration clearOverlayDuration = Duration(milliseconds: 2000);

  /// Tier (1〜5) → 1 optimal turn あたりの加算秒
  static const Map<int, double> tierMultipliers = {
    1: 3.0,
    2: 2.5,
    3: 2.0,
    4: 1.5,
    5: 1.0,
  };

  /// 出題枠ごとの score 帯（仕様 #7）
  static const List<TimeAttackScoreSlot> scoreSlots = [
    TimeAttackScoreSlot(count: 1, minScore: 2, maxScore: 2), // Q1
    TimeAttackScoreSlot(count: 4, minScore: 3, maxScore: 5), // Q2-5
    TimeAttackScoreSlot(count: 5, minScore: 6, maxScore: 6), // Q6-10
    TimeAttackScoreSlot(count: 10, minScore: 7, maxScore: 8), // Q11-20
    TimeAttackScoreSlot(count: 10, minScore: 9, maxScore: 10), // Q21-30
    TimeAttackScoreSlot(count: 10, minScore: 11, maxScore: 12), // Q31-40
    TimeAttackScoreSlot(count: 6, minScore: 13, maxScore: 14), // Q41-46
    TimeAttackScoreSlot(count: 4, minScore: 15, maxScore: 999), // Q47-50
  ];

  /// 0-based question index → Tier 1..5
  static int tierForQuestionIndex(int index) {
    if (index < 0) return 1;
    if (index >= totalLevels) return 5;
    return (index ~/ 10) + 1;
  }

  static double multiplierForTier(int tier) =>
      tierMultipliers[tier] ?? tierMultipliers[5]!;

  static int timeBonusMs({
    required int optimalTurns,
    required int tier,
  }) {
    final seconds = optimalTurns * multiplierForTier(tier);
    return (seconds * 1000).round();
  }

  static int clearBonusPoints(int clearCount) {
    if (clearCount <= 0) return 0;
    return clearCount * clearBonusPerClear;
  }

  static int remainingTimeBonusPoints(int remainingMs) {
    if (remainingMs <= 0) return 0;
    return (remainingMs ~/ timeBonusUnitMs) * timeBonusPointsPerUnit;
  }
}

class TimeAttackScoreSlot {
  final int count;
  final int minScore;
  final int maxScore;

  const TimeAttackScoreSlot({
    required this.count,
    required this.minScore,
    required this.maxScore,
  });

  bool matches(int score) => score >= minScore && score <= maxScore;
}
