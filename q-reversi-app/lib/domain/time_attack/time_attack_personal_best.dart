/// ローカル保存する自己ベスト1件
class TimeAttackPersonalBest {
  final int clearCount;
  final int maxCombo;
  final int comboBonus;
  final int timeBonusPoints;
  final int totalScore;
  final DateTime achievedAt;

  const TimeAttackPersonalBest({
    required this.clearCount,
    required this.maxCombo,
    required this.comboBonus,
    required this.timeBonusPoints,
    required this.totalScore,
    required this.achievedAt,
  });

  Map<String, Object> toJson() => {
        'clearCount': clearCount,
        'maxCombo': maxCombo,
        'comboBonus': comboBonus,
        'timeBonusPoints': timeBonusPoints,
        'totalScore': totalScore,
        'achievedAt': achievedAt.toIso8601String(),
      };

  factory TimeAttackPersonalBest.fromJson(Map<String, dynamic> json) {
    return TimeAttackPersonalBest(
      clearCount: json['clearCount'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      comboBonus: json['comboBonus'] as int? ?? 0,
      timeBonusPoints: json['timeBonusPoints'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      achievedAt: DateTime.tryParse(json['achievedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// 現行記録の方が自己ベストとして優先されるか
  /// （TOTAL SCORE が高い / 同点なら先着＝既存を維持）
  bool isBeatenBy(TimeAttackPersonalBest candidate) {
    if (candidate.totalScore > totalScore) return true;
    return false;
  }
}
