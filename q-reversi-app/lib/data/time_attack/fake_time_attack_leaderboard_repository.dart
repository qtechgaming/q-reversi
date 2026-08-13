import 'dart:math';

import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/time_attack/time_attack_config.dart';
import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import 'time_attack_leaderboard_repository.dart';

/// ローカル検証用のモックランキング（Firebaseなし）
///
/// 他プレイヤーは固定シードのボット。自分の行は SharedPreferences の自己ベストを反映。
class FakeTimeAttackLeaderboardRepository
    implements TimeAttackLeaderboardRepository {
  FakeTimeAttackLeaderboardRepository({
    Random? random,
    TimeAttackLocalProfileService? profileService,
  })  : _seedRandom = random,
        _profile = profileService ?? TimeAttackLocalProfileService();

  final Random? _seedRandom;
  final TimeAttackLocalProfileService _profile;

  static const _nicknames = [
    '量子ねこ',
    'ゲート職人',
    'H回転マスター',
    'CNOT使い',
    '白黒揃え',
    '最短ハンター',
    'タイム職人',
    'パーフェクト狙い',
    '重ね合わせ屋',
    'SWAP好き',
    '測定回避',
    'エンタングル耐性',
    '盤面職人',
    'クールタイム無視',
    '量子うさぎ',
    'リバーシ博士',
    'PhaseKick',
    'BellPair',
    'Hadamard流',
    'Z軸番長',
  ];

  @override
  Future<TimeAttackLeaderboardSnapshot> fetchLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // 毎回同じボット分布になるようシード固定
    final random = _seedRandom ?? Random(42);
    final now = DateTime.now();
    final entries = <TimeAttackLeaderboardEntry>[];

    for (var i = 0; i < 220; i++) {
      final clear = _clearForIndex(i, random);
      final maxCombo = 1 + random.nextInt(12);
      final comboBonus = _comboBonusFor(maxCombo);
      final timeBonus = clear >= TimeAttackConfig.totalLevels
          ? 50 + random.nextInt(400)
          : 0;
      entries.add(
        TimeAttackLeaderboardEntry(
          uid: 'bot-$i',
          nickname:
              '${_nicknames[i % _nicknames.length]}${i ~/ _nicknames.length + 1}',
          clearCount: clear,
          maxCombo: maxCombo,
          comboBonus: comboBonus,
          timeBonusPoints: timeBonus,
          achievedAt:
              now.subtract(Duration(hours: i * 3 + random.nextInt(5))),
        ),
      );
    }

    final best = await _profile.getPersonalBest();
    if (best != null) {
      final taken = entries.map((e) => e.nickname);
      final nickname = await _profile.getOrAssignNickname(takenNames: taken);
      final uid = await _profile.getLocalUid();
      entries.add(
        TimeAttackLeaderboardEntry(
          uid: uid,
          nickname: nickname,
          clearCount: best.clearCount,
          maxCombo: best.maxCombo,
          comboBonus: best.comboBonus,
          timeBonusPoints: best.timeBonusPoints,
          achievedAt: best.achievedAt,
          isMe: true,
        ),
      );
    }

    entries.sort(_compareEntries);

    return TimeAttackLeaderboardSnapshot(rankedEntries: entries);
  }

  int _clearForIndex(int i, Random random) {
    if (i < 5) return 50;
    if (i < 15) return 40 + random.nextInt(10);
    if (i < 40) return 25 + random.nextInt(15);
    if (i < 100) return 12 + random.nextInt(14);
    if (i < 160) return 6 + random.nextInt(8);
    return 1 + random.nextInt(6);
  }

  int _comboBonusFor(int maxCombo) {
    var sum = 0;
    for (var c = 1; c <= maxCombo; c++) {
      sum += c * TimeAttackConfig.comboPointStep;
    }
    return sum;
  }

  static int _compareEntries(
    TimeAttackLeaderboardEntry a,
    TimeAttackLeaderboardEntry b,
  ) {
    final scoreCmp = b.totalScore.compareTo(a.totalScore);
    if (scoreCmp != 0) return scoreCmp;
    return a.achievedAt.compareTo(b.achievedAt);
  }
}
