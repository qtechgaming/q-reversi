/// 量子AI対戦ランキング1件分（勝利数のみ）
class VsQuantumLeaderboardEntry {
  final String uid;
  final String nickname;
  final int wins;
  final DateTime achievedAt;
  final bool isMe;

  const VsQuantumLeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.wins,
    required this.achievedAt,
    this.isMe = false,
  });
}

/// ランキング取得結果（モック / 将来のサーバー共通）
class VsQuantumLeaderboardSnapshot {
  /// 勝利数降順でソート済み（最大1000件想定）
  final List<VsQuantumLeaderboardEntry> rankedEntries;

  final int displayLimit;
  final int personalRankLimit;

  const VsQuantumLeaderboardSnapshot({
    required this.rankedEntries,
    this.displayLimit = 100,
    this.personalRankLimit = 1000,
  });

  List<VsQuantumLeaderboardEntry> get topDisplayEntries =>
      rankedEntries.take(displayLimit).toList();

  int? get myRank {
    final index = rankedEntries.indexWhere((e) => e.isMe);
    if (index < 0) return null;
    if (index >= personalRankLimit) return null;
    return index + 1;
  }

  VsQuantumLeaderboardEntry? get myEntry {
    for (final e in rankedEntries) {
      if (e.isMe) return e;
    }
    return null;
  }
}
