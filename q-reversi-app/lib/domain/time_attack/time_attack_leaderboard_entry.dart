import 'time_attack_config.dart';

/// ランキング1件分
class TimeAttackLeaderboardEntry {
  final String uid;
  final String nickname;
  final int clearCount;
  final int maxCombo;
  final int comboBonus;
  final int timeBonusPoints;
  final DateTime achievedAt;
  final bool isMe;

  const TimeAttackLeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.clearCount,
    required this.maxCombo,
    required this.comboBonus,
    required this.timeBonusPoints,
    required this.achievedAt,
    this.isMe = false,
  });

  int get clearBonusPoints =>
      TimeAttackConfig.clearBonusPoints(clearCount);

  /// CLEAR BONUS + COMBO BONUS + TIME BONUS
  int get totalScore => clearBonusPoints + comboBonus + timeBonusPoints;
}

/// ランキング取得結果（モック / 将来のサーバー共通）
class TimeAttackLeaderboardSnapshot {
  /// TOTAL SCORE 降順でソート済み（最大1000件想定）
  final List<TimeAttackLeaderboardEntry> rankedEntries;

  /// 一覧に出す件数（TOP100）
  final int displayLimit;

  /// 自分の順位把握上限（TOP1000）
  final int personalRankLimit;

  const TimeAttackLeaderboardSnapshot({
    required this.rankedEntries,
    this.displayLimit = 100,
    this.personalRankLimit = 1000,
  });

  List<TimeAttackLeaderboardEntry> get topDisplayEntries =>
      rankedEntries.take(displayLimit).toList();

  /// 1-based。personalRankLimit 外または未登録なら null
  int? get myRank {
    final index = rankedEntries.indexWhere((e) => e.isMe);
    if (index < 0) return null;
    if (index >= personalRankLimit) return null;
    return index + 1;
  }

  TimeAttackLeaderboardEntry? get myEntry {
    for (final e in rankedEntries) {
      if (e.isMe) return e;
    }
    return null;
  }

  bool get isMyRankVisible => myRank != null;
}
