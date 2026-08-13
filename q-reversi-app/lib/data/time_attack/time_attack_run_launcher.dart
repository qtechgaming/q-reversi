import '../../domain/entities/challenge_level.dart';
import '../../domain/services/challenge_level_loader.dart';
import '../../domain/time_attack/time_attack_config.dart';
import '../firebase/time_attack_run_remote_service.dart';

class TimeAttackPreparedRun {
  final String runId;
  final List<ChallengeLevel> sequence;

  const TimeAttackPreparedRun({
    required this.runId,
    required this.sequence,
  });
}

/// START / リトライ共通のラン開始準備
class TimeAttackRunLauncher {
  TimeAttackRunLauncher({
    TimeAttackRunRemoteService? remote,
    ChallengeLevelLoader? loader,
  })  : _remote = remote ?? TimeAttackRunRemoteService(),
        _loader = loader ?? ChallengeLevelLoader();

  final TimeAttackRunRemoteService _remote;
  final ChallengeLevelLoader _loader;

  Future<TimeAttackPreparedRun> prepare() async {
    final start = await _remote.startRun();
    if (start.levels.length != TimeAttackConfig.totalLevels) {
      throw TimeAttackRunRemoteException(
        'TIME ATTACKの開始には通信が必要です。',
      );
    }

    final allLevels = await _loader.loadAllLevels();
    final byId = {
      for (final level in allLevels) level.level: level,
    };
    final sequence = <ChallengeLevel>[];
    for (final info in start.levels) {
      final level = byId[info.levelId];
      if (level == null) {
        throw TimeAttackRunRemoteException(
          '問題データが見つかりません（level ${info.levelId}）',
        );
      }
      sequence.add(level);
    }

    return TimeAttackPreparedRun(
      runId: start.runId,
      sequence: sequence,
    );
  }
}
