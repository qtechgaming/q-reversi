class TimeAttackLevelResult {
  final int levelId;
  final bool cleared;
  final bool isPerfect;
  final int turnsUsed;
  final int optimalTurns;
  final int elapsedMs;
  final int resetCount;
  final int score;
  final int tier;

  const TimeAttackLevelResult({
    required this.levelId,
    required this.cleared,
    required this.isPerfect,
    required this.turnsUsed,
    required this.optimalTurns,
    required this.elapsedMs,
    required this.resetCount,
    required this.score,
    required this.tier,
  });
}
