import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'challenge_level.dart';

/// チャレンジ進捗
class ChallengeProgress extends Equatable {
  final int level;
  final bool isCompleted;
  final int stars; // 0-3
  final int turnsUsed;

  const ChallengeProgress({
    required this.level,
    this.isCompleted = false,
    this.stars = 0,
    this.turnsUsed = 0,
  });

  ChallengeProgress copyWith({
    int? level,
    bool? isCompleted,
    int? stars,
    int? turnsUsed,
  }) {
    return ChallengeProgress(
      level: level ?? this.level,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      turnsUsed: turnsUsed ?? this.turnsUsed,
    );
  }

  @override
  List<Object?> get props => [level, isCompleted, stars, turnsUsed];
}

/// チャレンジ進捗管理
class ChallengeProgressManager {
  final Map<int, ChallengeProgress> _progress;

  ChallengeProgressManager(this._progress);

  /// レベルが完了しているか
  bool isLevelCompleted(int level) {
    return _progress[level]?.isCompleted ?? false;
  }

  /// ステージ0（チュートリアル続き）をすべてクリアしたか
  bool isStage0Completed() {
    for (int level = ChallengeLevel.stage0FirstLevel;
        level <= ChallengeLevel.stage0LastLevel;
        level++) {
      if (!isLevelCompleted(level)) {
        return false;
      }
    }
    return true;
  }

  /// ステージ1（本編レベル1–30）を1問でもクリアしているか
  /// ステージ0追加前の既存ユーザー向け互換判定に使う
  bool hasClearedAnyStage1Level() {
    final range = ChallengeLevel.stageLevelRange(1);
    for (int level = range.$1; level <= range.$2; level++) {
      if (isLevelCompleted(level)) {
        return true;
      }
    }
    return false;
  }

  /// ステージ0ゲートを満たしているか
  /// 新規: ステージ0全クリア / 既存: ステージ1を1問以上クリア済みなら通過
  bool isStage0RequirementMet() {
    return isStage0Completed() || hasClearedAnyStage1Level();
  }

  /// レベルがアンロックされているか
  bool isLevelUnlocked(int level) {
    // デバッグモード（評価時）では全レベルをアンロック
    if (kDebugMode) return true;

    // ステージ0は先頭から順に解放
    if (ChallengeLevel.isStage0Level(level)) {
      if (level == ChallengeLevel.stage0FirstLevel) return true;
      return isLevelCompleted(level - 1);
    }

    // 本編はステージ0要件を満たしてから解放開始（以降は従来どおり前レベル順）
    if (!isStage0RequirementMet()) return false;
    if (level == 1) return true;
    return isLevelCompleted(level - 1);
  }

  /// ステージがアンロックされているか
  bool isStageUnlocked(int stageNumber) {
    // デバッグモード（評価時）では全ステージをアンロック
    if (kDebugMode) return true;

    if (stageNumber == 0) return true;

    // ステージ0要件を満たせばステージ1を解放（既存ユーザーはステージ1進捗で通過可）
    if (!isStage0RequirementMet()) return false;
    if (stageNumber == 1) return true;

    // 以降は前ステージ全クリアで次ステージ解放（従来どおり）
    final previousStageStart =
        (stageNumber - 2) * ChallengeLevel.mainStageSize + 1;
    final previousStageEnd =
        (stageNumber - 1) * ChallengeLevel.mainStageSize;
    for (int level = previousStageStart; level <= previousStageEnd; level++) {
      if (!isLevelCompleted(level)) {
        return false;
      }
    }
    return true;
  }

  /// ステージ内の完了レベル数
  int getCompletedLevelsInStage(int stageNumber) {
    final range = ChallengeLevel.stageLevelRange(stageNumber);
    int count = 0;
    for (int level = range.$1; level <= range.$2; level++) {
      if (isLevelCompleted(level)) {
        count++;
      }
    }
    return count;
  }

  /// ステージ内の全レベルが★3つか
  bool isStagePerfect(int stageNumber) {
    final range = ChallengeLevel.stageLevelRange(stageNumber);
    for (int level = range.$1; level <= range.$2; level++) {
      final progress = _progress[level];
      if (progress == null || !progress.isCompleted || progress.stars != 3) {
        return false;
      }
    }
    return true;
  }

  /// 進捗を更新
  ChallengeProgressManager updateProgress(ChallengeProgress progress) {
    final newProgress = Map<int, ChallengeProgress>.from(_progress);
    newProgress[progress.level] = progress;
    return ChallengeProgressManager(newProgress);
  }

  /// すべての進捗を取得
  Map<int, ChallengeProgress> get allProgress => Map.unmodifiable(_progress);
}



