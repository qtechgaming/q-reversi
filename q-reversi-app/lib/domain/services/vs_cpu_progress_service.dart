import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/game_mode.dart';

/// 対CPU戦1試合の結果（人間視点）
enum VsCpuGameOutcome {
  win,
  loss,
  draw,
}

/// VS・CPU戦ごとの勝ち・負け・引き分け回数
class VsCpuStats {
  const VsCpuStats({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  final int wins;
  final int losses;
  final int draws;

  int get played => wins + losses + draws;

  double get winRate => played == 0 ? 0.0 : wins / played;

  VsCpuStats copyWith({int? wins, int? losses, int? draws}) {
    return VsCpuStats(
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
    );
  }

  static VsCpuStats _fromJsonEntry(Map<String, dynamic> entry) {
    final wins = (entry['wins'] as num?)?.toInt() ?? 0;
    final hasBreakdown =
        entry.containsKey('losses') || entry.containsKey('draws');
    if (hasBreakdown) {
      final losses = (entry['losses'] as num?)?.toInt() ?? 0;
      final draws = (entry['draws'] as num?)?.toInt() ?? 0;
      return VsCpuStats(
        wins: wins < 0 ? 0 : wins,
        losses: losses < 0 ? 0 : losses,
        draws: draws < 0 ? 0 : draws,
      );
    }
    // 旧形式: played + wins のみ（引き分けは区別できないため残りは負け扱い）
    final played = (entry['played'] as num?)?.toInt() ?? 0;
    final safeWins = wins < 0 ? 0 : wins;
    final safePlayed = played < 0 ? 0 : played;
    final losses = (safePlayed - safeWins).clamp(0, 1 << 30);
    return VsCpuStats(wins: safeWins, losses: losses, draws: 0);
  }
}

/// 永続化済みのVS CPU進捗
class VsCpuProgressSnapshot {
  VsCpuProgressSnapshot({
    required this.unlockedMaxIndex,
    required Map<AIDifficulty, VsCpuStats> statsIn,
  }) : stats = Map.unmodifiable(
          Map.fromEntries(
            VsCpuProgressService.difficultiesOrder
                .map((d) => MapEntry(d, statsIn[d] ?? const VsCpuStats())),
          ),
        );

  /// 0=初級まで解放 … 3=量子AIまで解放
  final int unlockedMaxIndex;
  final Map<AIDifficulty, VsCpuStats> stats;

  bool isUnlocked(AIDifficulty d) {
    // 管理者モード（デバッグビルド）では全難易度を解放
    if (kDebugMode) {
      return VsCpuProgressService.difficultiesOrder.contains(d);
    }
    final i = VsCpuProgressService.difficultiesOrder.indexOf(d);
    if (i < 0) return false;
    return i <= unlockedMaxIndex;
  }
}

/// VSモード・CPU難易度の解放と対戦記録
class VsCpuProgressService {
  static const String _prefsKey = 'vs_cpu_progress_v1';

  static const List<AIDifficulty> difficultiesOrder = [
    AIDifficulty.beginner,
    AIDifficulty.intermediate,
    AIDifficulty.advanced,
    AIDifficulty.quantum,
  ];

  static String _difficultyKey(AIDifficulty d) => d.name;

  Future<VsCpuProgressSnapshot> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.reload();
      } catch (_) {}

      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        return VsCpuProgressSnapshot(unlockedMaxIndex: 0, statsIn: {});
      }

      final decoded = json.decode(raw) as Map<String, dynamic>;
      final unlocked = (decoded['unlockedMaxIndex'] as num?)?.toInt() ?? 0;
      final clampedUnlocked = unlocked.clamp(0, difficultiesOrder.length - 1);

      final statsMap = <AIDifficulty, VsCpuStats>{};
      final statsJson = decoded['stats'];
      if (statsJson is Map<String, dynamic>) {
        for (final d in difficultiesOrder) {
          final key = _difficultyKey(d);
          final entry = statsJson[key];
          if (entry is Map<String, dynamic>) {
            statsMap[d] = VsCpuStats._fromJsonEntry(entry);
          }
        }
      }

      return VsCpuProgressSnapshot(
        unlockedMaxIndex: clampedUnlocked,
        statsIn: statsMap,
      );
    } catch (_) {
      return VsCpuProgressSnapshot(unlockedMaxIndex: 0, statsIn: {});
    }
  }

  Future<void> save(VsCpuProgressSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsOut = <String, dynamic>{};
      for (final d in difficultiesOrder) {
        final s = snapshot.stats[d] ?? const VsCpuStats();
        statsOut[_difficultyKey(d)] = {
          'wins': s.wins,
          'losses': s.losses,
          'draws': s.draws,
        };
      }
      await prefs.setString(
        _prefsKey,
        json.encode({
          'unlockedMaxIndex': snapshot.unlockedMaxIndex,
          'stats': statsOut,
        }),
      );
    } catch (_) {}
  }

  /// 対CPU戦の結果を記録（人間は常に白・プレイヤー1想定）
  Future<VsCpuProgressSnapshot> recordVsCpuGame({
    required AIDifficulty difficulty,
    required VsCpuGameOutcome outcome,
  }) async {
    final latest = await load();
    final battleIndex = difficultiesOrder.indexOf(difficulty);
    if (battleIndex < 0) return latest;

    final prev = latest.stats[difficulty] ?? const VsCpuStats();
    final nextStats = Map<AIDifficulty, VsCpuStats>.from(latest.stats);

    switch (outcome) {
      case VsCpuGameOutcome.win:
        nextStats[difficulty] = prev.copyWith(wins: prev.wins + 1);
      case VsCpuGameOutcome.loss:
        nextStats[difficulty] = prev.copyWith(losses: prev.losses + 1);
      case VsCpuGameOutcome.draw:
        nextStats[difficulty] = prev.copyWith(draws: prev.draws + 1);
    }

    var nextUnlocked = latest.unlockedMaxIndex;
    if (outcome == VsCpuGameOutcome.win) {
      final bump = (battleIndex + 1).clamp(0, difficultiesOrder.length - 1);
      if (bump > nextUnlocked) {
        nextUnlocked = bump;
      }
    }

    final snapshot = VsCpuProgressSnapshot(
      unlockedMaxIndex: nextUnlocked,
      statsIn: nextStats,
    );
    await save(snapshot);
    return snapshot;
  }
}
