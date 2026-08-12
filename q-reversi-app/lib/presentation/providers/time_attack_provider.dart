import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/challenge_level.dart';
import '../../domain/time_attack/time_attack_config.dart';
import '../../domain/time_attack/time_attack_level_result.dart';
import '../../domain/time_attack/time_attack_run_state.dart';

/// TIME ATTACK 進行管理。残り時間の Source of Truth は Stopwatch。
class TimeAttackProvider extends ChangeNotifier {
  TimeAttackRunState _state;
  final Stopwatch _playStopwatch = Stopwatch();
  final Stopwatch _levelStopwatch = Stopwatch();
  Timer? _uiTimer;
  int _remainingAtSegmentStartMs = 0;

  TimeAttackProvider(List<ChallengeLevel> sequence)
      : _state = TimeAttackRunState.initial(sequence);

  TimeAttackRunState get state => _state;

  void startRun() {
    if (_state.isFinished) return;
    _remainingAtSegmentStartMs = _state.remainingMs;
    _playStopwatch
      ..reset()
      ..start();
    _levelStopwatch
      ..reset()
      ..start();
    _state = _state.copyWith(isTimerRunning: true);
    _startUiTicker();
    notifyListeners();
  }

  void _startUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(TimeAttackConfig.uiTickInterval, (_) {
      _syncRemainingFromStopwatch();
    });
  }

  void _syncRemainingFromStopwatch({bool notify = true}) {
    if (!_state.isTimerRunning || _state.isTransitioning || _state.isFinished) {
      return;
    }

    final remaining =
        _remainingAtSegmentStartMs - _playStopwatch.elapsedMilliseconds;
    final levelElapsed = _levelStopwatch.elapsedMilliseconds;

    if (remaining <= 0) {
      _handleTimeUp(levelElapsed);
      return;
    }

    _state = _state.copyWith(
      remainingMs: remaining,
      currentLevelElapsedMs: levelElapsed,
    );
    if (notify) notifyListeners();
  }

  void _pauseTimerForTransition() {
    _syncRemainingFromStopwatch(notify: false);
    _playStopwatch.stop();
    _levelStopwatch.stop();
    _uiTimer?.cancel();
    _uiTimer = null;
    _state = _state.copyWith(
      isTimerRunning: false,
      isTransitioning: true,
    );
  }

  void _resumeTimerAfterTransition() {
    _remainingAtSegmentStartMs = _state.remainingMs;
    _playStopwatch
      ..reset()
      ..start();
    _levelStopwatch
      ..reset()
      ..start();
    _state = _state.copyWith(
      isTimerRunning: true,
      isTransitioning: false,
      currentLevelElapsedMs: 0,
      clearClearFlash: true,
    );
    _startUiTicker();
  }

  /// App resume 時などに呼び、経過を反映する（background でも止めない前提）
  void refreshFromWallClock() {
    if (_state.isFinished) return;
    if (_state.isTransitioning) return;
    if (!_state.isTimerRunning) return;
    _syncRemainingFromStopwatch();
  }

  void registerReset() {
    if (!_state.canInteract) return;
    _state = _state.copyWith(
      currentLevelResetCount: _state.currentLevelResetCount + 1,
      comboStreak: 0,
    );
    notifyListeners();
  }

  /// クリア処理。戻り値の flash を UI で表示し、[completeTransition] を呼ぶ。
  TimeAttackClearFlash? registerClear({
    required int turnsUsed,
  }) {
    if (_state.isFinished || _state.isTransitioning) return null;
    if (!_state.isTimerRunning && _state.remainingMs <= 0) return null;

    _pauseTimerForTransition();

    final level = _state.currentLevel;
    final tier = _state.currentTier;
    final elapsedMs = _levelStopwatch.elapsedMilliseconds;
    final isPerfect =
        turnsUsed == level.optimalTurns && _state.currentLevelResetCount == 0;

    var comboStreak = _state.comboStreak;
    var comboBonus = _state.comboBonus;
    var comboBonusGained = 0;
    var maxCombo = _state.maxCombo;

    if (isPerfect) {
      comboStreak += 1;
      comboBonusGained = comboStreak * TimeAttackConfig.comboPointStep;
      comboBonus += comboBonusGained;
      if (comboStreak > maxCombo) maxCombo = comboStreak;
    } else {
      comboStreak = 0;
    }

    final result = TimeAttackLevelResult(
      levelId: level.level,
      cleared: true,
      isPerfect: isPerfect,
      turnsUsed: turnsUsed,
      optimalTurns: level.optimalTurns,
      elapsedMs: elapsedMs,
      resetCount: _state.currentLevelResetCount,
      score: level.timeAttackScore,
      tier: tier,
    );

    final newResults = [..._state.results, result];
    final newClearCount = _state.clearCount + 1;
    final isLast = _state.currentIndex >= TimeAttackConfig.totalLevels - 1;

    if (isLast) {
      final timeBonusPoints =
          TimeAttackConfig.remainingTimeBonusPoints(_state.remainingMs);
      final flash = TimeAttackClearFlash(
        isPerfect: isPerfect,
        comboStreak: comboStreak,
        comboBonusGained: comboBonusGained,
        timeBonusMs: 0,
        isAllClear: true,
      );
      _state = _state.copyWith(
        clearCount: newClearCount,
        comboStreak: comboStreak,
        maxCombo: maxCombo,
        comboBonus: comboBonus,
        timeBonusPoints: timeBonusPoints,
        results: newResults,
        isFinished: true,
        isAllClear: true,
        isTransitioning: true,
        endReason: TimeAttackEndReason.allClear,
        clearFlash: flash,
      );
      notifyListeners();
      return flash;
    }

    final nextIndex = _state.currentIndex + 1;
    final nextTier = TimeAttackConfig.tierForQuestionIndex(nextIndex);
    final nextLevel = _state.sequence[nextIndex];
    final bonusMs = TimeAttackConfig.timeBonusMs(
      optimalTurns: nextLevel.optimalTurns,
      tier: nextTier,
    );
    final newRemaining = (_state.remainingMs + bonusMs)
        .clamp(0, TimeAttackConfig.maxTime.inMilliseconds);

    final flash = TimeAttackClearFlash(
      isPerfect: isPerfect,
      comboStreak: comboStreak,
      comboBonusGained: comboBonusGained,
      timeBonusMs: bonusMs,
      isAllClear: false,
      nextGoalLabel: nextLevel.victoryCondition.displayName,
      nextOptimalTurns: nextLevel.optimalTurns,
    );

    _state = _state.copyWith(
      currentIndex: nextIndex,
      clearCount: newClearCount,
      remainingMs: newRemaining,
      comboStreak: comboStreak,
      maxCombo: maxCombo,
      comboBonus: comboBonus,
      currentLevelResetCount: 0,
      currentLevelElapsedMs: 0,
      results: newResults,
      clearFlash: flash,
    );
    notifyListeners();
    return flash;
  }

  /// CLEAR 演出後に呼ぶ。次問へ進むか結果画面へ。
  void completeTransition() {
    if (_state.isFinished) {
      _state = _state.copyWith(
        isTransitioning: false,
        clearClearFlash: true,
      );
      notifyListeners();
      return;
    }

    _resumeTimerAfterTransition();
    notifyListeners();
  }

  void _handleTimeUp(int levelElapsedMs) {
    _playStopwatch.stop();
    _levelStopwatch.stop();
    _uiTimer?.cancel();
    _uiTimer = null;

    final level = _state.currentLevel;
    final result = TimeAttackLevelResult(
      levelId: level.level,
      cleared: false,
      isPerfect: false,
      turnsUsed: 0,
      optimalTurns: level.optimalTurns,
      elapsedMs: levelElapsedMs,
      resetCount: _state.currentLevelResetCount,
      score: level.timeAttackScore,
      tier: _state.currentTier,
    );

    _state = _state.copyWith(
      remainingMs: 0,
      isTimerRunning: false,
      isTransitioning: false,
      isFinished: true,
      isAllClear: false,
      endReason: TimeAttackEndReason.timeUp,
      results: [..._state.results, result],
      clearClearFlash: true,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _playStopwatch.stop();
    _levelStopwatch.stop();
    super.dispose();
  }
}
