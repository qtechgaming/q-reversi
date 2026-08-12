import '../entities/challenge_level.dart';
import 'time_attack_config.dart';
import 'time_attack_level_result.dart';

enum TimeAttackEndReason {
  playing,
  timeUp,
  allClear,
}

/// CLEAR 演出用の一時情報
class TimeAttackClearFlash {
  final bool isPerfect;
  final int comboStreak;
  final int comboBonusGained;
  final int timeBonusMs;
  final bool isAllClear;

  /// 次盤面のゴール条件表示用（ALL CLEAR 時は null）
  final String? nextGoalLabel;

  /// 次盤面の最短手数（ALL CLEAR 時は null）
  final int? nextOptimalTurns;

  const TimeAttackClearFlash({
    required this.isPerfect,
    required this.comboStreak,
    required this.comboBonusGained,
    required this.timeBonusMs,
    required this.isAllClear,
    this.nextGoalLabel,
    this.nextOptimalTurns,
  });
}

class TimeAttackRunState {
  final List<ChallengeLevel> sequence;
  final int currentIndex;
  final int clearCount;
  final int remainingMs;
  final int comboStreak;
  final int maxCombo;
  final int comboBonus;
  final int timeBonusPoints;
  final int currentLevelResetCount;
  final int currentLevelElapsedMs;
  final List<TimeAttackLevelResult> results;
  final bool isTimerRunning;
  final bool isTransitioning;
  final bool isFinished;
  final bool isAllClear;
  final TimeAttackEndReason endReason;
  final TimeAttackClearFlash? clearFlash;

  const TimeAttackRunState({
    required this.sequence,
    required this.currentIndex,
    required this.clearCount,
    required this.remainingMs,
    required this.comboStreak,
    required this.maxCombo,
    required this.comboBonus,
    required this.timeBonusPoints,
    required this.currentLevelResetCount,
    required this.currentLevelElapsedMs,
    required this.results,
    required this.isTimerRunning,
    required this.isTransitioning,
    required this.isFinished,
    required this.isAllClear,
    required this.endReason,
    this.clearFlash,
  });

  factory TimeAttackRunState.initial(List<ChallengeLevel> sequence) {
    assert(sequence.length == TimeAttackConfig.totalLevels);
    return TimeAttackRunState(
      sequence: sequence,
      currentIndex: 0,
      clearCount: 0,
      remainingMs: TimeAttackConfig.initialTime.inMilliseconds,
      comboStreak: 0,
      maxCombo: 0,
      comboBonus: 0,
      timeBonusPoints: 0,
      currentLevelResetCount: 0,
      currentLevelElapsedMs: 0,
      results: const [],
      isTimerRunning: false,
      isTransitioning: false,
      isFinished: false,
      isAllClear: false,
      endReason: TimeAttackEndReason.playing,
    );
  }

  /// UIプレビュー用（TIME UP）
  factory TimeAttackRunState.previewTimeUp({
    int clearCount = 17,
    int maxCombo = 4,
    int comboBonus = 100,
  }) {
    return TimeAttackRunState(
      sequence: const [],
      currentIndex: clearCount.clamp(0, TimeAttackConfig.totalLevels - 1),
      clearCount: clearCount,
      remainingMs: 0,
      comboStreak: 0,
      maxCombo: maxCombo,
      comboBonus: comboBonus,
      timeBonusPoints: 0,
      currentLevelResetCount: 0,
      currentLevelElapsedMs: 0,
      results: const [],
      isTimerRunning: false,
      isTransitioning: false,
      isFinished: true,
      isAllClear: false,
      endReason: TimeAttackEndReason.timeUp,
    );
  }

  /// UIプレビュー用（50問 ALL CLEAR）
  factory TimeAttackRunState.previewAllClear({
    int maxCombo = 8,
    int comboBonus = 360,
    int remainingMs = 24700,
  }) {
    final timeBonus =
        TimeAttackConfig.remainingTimeBonusPoints(remainingMs);
    return TimeAttackRunState(
      sequence: const [],
      currentIndex: TimeAttackConfig.totalLevels - 1,
      clearCount: TimeAttackConfig.totalLevels,
      remainingMs: remainingMs,
      comboStreak: maxCombo,
      maxCombo: maxCombo,
      comboBonus: comboBonus,
      timeBonusPoints: timeBonus,
      currentLevelResetCount: 0,
      currentLevelElapsedMs: 0,
      results: const [],
      isTimerRunning: false,
      isTransitioning: false,
      isFinished: true,
      isAllClear: true,
      endReason: TimeAttackEndReason.allClear,
    );
  }

  ChallengeLevel get currentLevel => sequence[currentIndex];

  int get currentTier =>
      TimeAttackConfig.tierForQuestionIndex(currentIndex);

  int get questionNumber => currentIndex + 1;

  int get clearBonusPoints =>
      TimeAttackConfig.clearBonusPoints(clearCount);

  int get totalBonusPoints => comboBonus + timeBonusPoints;

  /// TOTAL SCORE = CLEAR BONUS + COMBO BONUS + TIME BONUS
  int get totalScore => clearBonusPoints + comboBonus + timeBonusPoints;

  bool get canInteract =>
      !isFinished && !isTransitioning && isTimerRunning && remainingMs > 0;

  TimeAttackRunState copyWith({
    List<ChallengeLevel>? sequence,
    int? currentIndex,
    int? clearCount,
    int? remainingMs,
    int? comboStreak,
    int? maxCombo,
    int? comboBonus,
    int? timeBonusPoints,
    int? currentLevelResetCount,
    int? currentLevelElapsedMs,
    List<TimeAttackLevelResult>? results,
    bool? isTimerRunning,
    bool? isTransitioning,
    bool? isFinished,
    bool? isAllClear,
    TimeAttackEndReason? endReason,
    TimeAttackClearFlash? clearFlash,
    bool clearClearFlash = false,
  }) {
    return TimeAttackRunState(
      sequence: sequence ?? this.sequence,
      currentIndex: currentIndex ?? this.currentIndex,
      clearCount: clearCount ?? this.clearCount,
      remainingMs: remainingMs ?? this.remainingMs,
      comboStreak: comboStreak ?? this.comboStreak,
      maxCombo: maxCombo ?? this.maxCombo,
      comboBonus: comboBonus ?? this.comboBonus,
      timeBonusPoints: timeBonusPoints ?? this.timeBonusPoints,
      currentLevelResetCount:
          currentLevelResetCount ?? this.currentLevelResetCount,
      currentLevelElapsedMs:
          currentLevelElapsedMs ?? this.currentLevelElapsedMs,
      results: results ?? this.results,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      isFinished: isFinished ?? this.isFinished,
      isAllClear: isAllClear ?? this.isAllClear,
      endReason: endReason ?? this.endReason,
      clearFlash: clearClearFlash ? null : (clearFlash ?? this.clearFlash),
    );
  }
}
