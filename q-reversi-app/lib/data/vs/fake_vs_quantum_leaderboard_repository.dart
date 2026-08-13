import 'dart:math';

import '../../domain/entities/game_mode.dart';
import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/services/vs_cpu_progress_service.dart';
import '../../domain/vs/vs_quantum_leaderboard_entry.dart';
import 'vs_quantum_leaderboard_repository.dart';

/// ローカル検証用の量子AI勝利数ランキング（Firebaseなし）
class FakeVsQuantumLeaderboardRepository
    implements VsQuantumLeaderboardRepository {
  FakeVsQuantumLeaderboardRepository({
    Random? random,
    TimeAttackLocalProfileService? profileService,
    VsCpuProgressService? progressService,
  })  : _seedRandom = random,
        _profile = profileService ?? TimeAttackLocalProfileService(),
        _progress = progressService ?? VsCpuProgressService();

  final Random? _seedRandom;
  final TimeAttackLocalProfileService _profile;
  final VsCpuProgressService _progress;

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
  Future<VsQuantumLeaderboardSnapshot> fetchLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final random = _seedRandom ?? Random(42);
    final now = DateTime.now();
    final entries = <VsQuantumLeaderboardEntry>[];

    for (var i = 0; i < 220; i++) {
      final wins = _winsForIndex(i, random);
      entries.add(
        VsQuantumLeaderboardEntry(
          uid: 'bot-$i',
          nickname:
              '${_nicknames[i % _nicknames.length]}${i ~/ _nicknames.length + 1}',
          wins: wins,
          achievedAt:
              now.subtract(Duration(hours: i * 3 + random.nextInt(5))),
        ),
      );
    }

    final snap = await _progress.load();
    final quantum = snap.stats[AIDifficulty.quantum] ?? const VsCpuStats();
    if (quantum.wins > 0) {
      final taken = entries.map((e) => e.nickname);
      final nickname = await _profile.getOrAssignNickname(takenNames: taken);
      final uid = await _profile.getLocalUid();
      entries.add(
        VsQuantumLeaderboardEntry(
          uid: uid,
          nickname: nickname,
          wins: quantum.wins,
          achievedAt: now,
          isMe: true,
        ),
      );
    }

    entries.sort(_compareEntries);
    return VsQuantumLeaderboardSnapshot(rankedEntries: entries);
  }

  int _winsForIndex(int i, Random random) {
    if (i < 5) return 40 + random.nextInt(20);
    if (i < 15) return 20 + random.nextInt(20);
    if (i < 40) return 10 + random.nextInt(12);
    if (i < 100) return 3 + random.nextInt(10);
    if (i < 160) return 1 + random.nextInt(4);
    return random.nextInt(3);
  }

  static int _compareEntries(
    VsQuantumLeaderboardEntry a,
    VsQuantumLeaderboardEntry b,
  ) {
    final winCmp = b.wins.compareTo(a.wins);
    if (winCmp != 0) return winCmp;
    return a.achievedAt.compareTo(b.achievedAt);
  }
}
