import 'package:equatable/equatable.dart';
import 'board.dart';
import 'gate_type.dart';

/// チャレンジレベル
class ChallengeLevel extends Equatable {
  /// ステージ0（チュートリアル続き）のレベル番号レンジ。本編(1-)と区別する。
  static const int stage0FirstLevel = 901;
  static const int stage0LevelCount = 15;
  static const int stage0LastLevel =
      stage0FirstLevel + stage0LevelCount - 1; // 915
  static const int mainStageSize = 30;

  final int level;
  final int optimalTurns;
  final List<GateType> availableGates;
  final VictoryCondition victoryCondition;
  final Board initialBoard;
  final String comment;

  /// 作者主観難易度（CSV `difficulty`、1〜10）
  final int difficulty;

  const ChallengeLevel({
    required this.level,
    required this.optimalTurns,
    required this.availableGates,
    required this.victoryCondition,
    required this.initialBoard,
    required this.comment,
    this.difficulty = 1,
  });

  /// TIME ATTACK 用 score（手数 + 難易度）
  int get timeAttackScore => optimalTurns + difficulty;

  static bool isStage0Level(int level) =>
      level >= stage0FirstLevel && level <= stage0LastLevel;

  /// CSVのレベルID（`0-1` / `1` / `42` など）を内部番号へ変換
  /// ステージ0は `0-N` → 901+(N-1)
  static int? parseLevelId(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final stage0Match = RegExp(r'^0-(\d+)$').firstMatch(s);
    if (stage0Match != null) {
      final n = int.tryParse(stage0Match.group(1)!);
      if (n == null || n < 1 || n > stage0LevelCount) return null;
      return stage0FirstLevel + n - 1;
    }

    return int.tryParse(s);
  }

  /// ステージ番号（0 = チュートリアル続き、1以降 = 本編）
  int get stageNumber {
    if (isStage0Level(level)) return 0;
    return ((level - 1) ~/ mainStageSize) + 1;
  }

  /// ステージ内のレベル番号（ステージ0は1-15、本編は1-30）
  int get levelInStage {
    if (isStage0Level(level)) {
      return level - stage0FirstLevel + 1;
    }
    return ((level - 1) % mainStageSize) + 1;
  }

  /// UI / CSV 表示用ラベル（ステージ0は 0-1 形式）
  String get displayLabel {
    if (isStage0Level(level)) {
      return '0-$levelInStage';
    }
    return '$level';
  }

  /// ステージのレベル番号レンジ（存在しない番号も含む理論レンジ）
  static (int start, int end) stageLevelRange(int stageNumber) {
    if (stageNumber == 0) {
      return (stage0FirstLevel, stage0LastLevel);
    }
    final start = (stageNumber - 1) * mainStageSize + 1;
    final end = stageNumber * mainStageSize;
    return (start, end);
  }

  /// 進行順（ステージ0 → 本編レベル昇順）
  static List<ChallengeLevel> orderedForProgression(
    List<ChallengeLevel> levels,
  ) {
    final stage0 = levels.where((l) => l.stageNumber == 0).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    final main = levels.where((l) => l.stageNumber != 0).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return [...stage0, ...main];
  }

  @override
  List<Object?> get props => [
        level,
        optimalTurns,
        availableGates,
        victoryCondition,
        initialBoard,
        comment,
        difficulty,
      ];
}

/// 勝利条件
enum VictoryCondition {
  allWhite,
  allBlack,
}

extension VictoryConditionExtension on VictoryCondition {
  static VictoryCondition? fromString(String str) {
    final normalized = str.trim().toLowerCase();
    if (normalized.contains('all white') || normalized == 'all white') {
      return VictoryCondition.allWhite;
    }
    if (normalized.contains('all black') || normalized == 'all black') {
      return VictoryCondition.allBlack;
    }
    return null;
  }

  String get displayName {
    switch (this) {
      case VictoryCondition.allWhite:
        return 'すべて白にする';
      case VictoryCondition.allBlack:
        return 'すべて黒にする';
    }
  }
}



