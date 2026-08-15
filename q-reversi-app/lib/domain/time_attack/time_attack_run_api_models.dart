class TimeAttackStartLevelInfo {
  final int levelId;
  final int tier;
  final int timeBonusMs;
  final int optimalTurns;
  final int score;
  final int difficulty;

  const TimeAttackStartLevelInfo({
    required this.levelId,
    required this.tier,
    required this.timeBonusMs,
    required this.optimalTurns,
    required this.score,
    required this.difficulty,
  });

  factory TimeAttackStartLevelInfo.fromJson(Map<String, dynamic> json) {
    return TimeAttackStartLevelInfo(
      levelId: (json['levelId'] as num).toInt(),
      tier: (json['tier'] as num?)?.toInt() ?? 1,
      timeBonusMs: (json['timeBonusMs'] as num?)?.toInt() ?? 0,
      optimalTurns: (json['optimalTurns'] as num?)?.toInt() ?? 1,
      score: (json['score'] as num?)?.toInt() ?? 0,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }
}

class TimeAttackStartResponse {
  final String runId;
  final int configVersion;
  final int initialTimeMs;
  final int maxTimeMs;
  final List<TimeAttackStartLevelInfo> levels;

  const TimeAttackStartResponse({
    required this.runId,
    required this.configVersion,
    required this.initialTimeMs,
    required this.maxTimeMs,
    required this.levels,
  });

  factory TimeAttackStartResponse.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'];
    final levels = <TimeAttackStartLevelInfo>[];
    if (rawLevels is List) {
      for (final item in rawLevels) {
        if (item is Map) {
          levels.add(
            TimeAttackStartLevelInfo.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    return TimeAttackStartResponse(
      runId: json['runId'] as String,
      configVersion: (json['configVersion'] as num?)?.toInt() ?? 1,
      initialTimeMs: (json['initialTimeMs'] as num?)?.toInt() ?? 30000,
      maxTimeMs: (json['maxTimeMs'] as num?)?.toInt() ?? 60000,
      levels: levels,
    );
  }
}

class TimeAttackSubmitLevelResultPayload {
  final int levelId;
  final bool cleared;
  final int turnsUsed;
  final int elapsedMs;
  final int resetCount;

  const TimeAttackSubmitLevelResultPayload({
    required this.levelId,
    required this.cleared,
    required this.turnsUsed,
    required this.elapsedMs,
    required this.resetCount,
  });

  Map<String, Object> toJson() => {
        'levelId': levelId,
        'cleared': cleared,
        'turnsUsed': turnsUsed,
        'elapsedMs': elapsedMs,
        'resetCount': resetCount,
      };
}

class TimeAttackOfficialResult {
  final String finishReason;
  final int clearCount;
  final int perfectCount;
  final int maxCombo;
  final int comboBonus;
  final int timeBonus;
  final int clearBonus;
  final int totalScore;
  final int remainingTimeMs;

  const TimeAttackOfficialResult({
    required this.finishReason,
    required this.clearCount,
    required this.perfectCount,
    required this.maxCombo,
    required this.comboBonus,
    required this.timeBonus,
    required this.clearBonus,
    required this.totalScore,
    required this.remainingTimeMs,
  });

  factory TimeAttackOfficialResult.fromJson(Map<String, dynamic> json) {
    return TimeAttackOfficialResult(
      finishReason: json['finishReason'] as String? ?? 'timeUp',
      clearCount: (json['clearCount'] as num?)?.toInt() ?? 0,
      perfectCount: (json['perfectCount'] as num?)?.toInt() ?? 0,
      maxCombo: (json['maxCombo'] as num?)?.toInt() ?? 0,
      comboBonus: (json['comboBonus'] as num?)?.toInt() ?? 0,
      timeBonus: (json['timeBonus'] as num?)?.toInt() ?? 0,
      clearBonus: (json['clearBonus'] as num?)?.toInt() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      remainingTimeMs: (json['remainingTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimeAttackSubmitResponse {
  final String runId;
  final bool alreadyCompleted;
  final TimeAttackOfficialResult officialResult;
  final String? displayName;

  const TimeAttackSubmitResponse({
    required this.runId,
    required this.alreadyCompleted,
    required this.officialResult,
    this.displayName,
  });

  factory TimeAttackSubmitResponse.fromJson(Map<String, dynamic> json) {
    final official = json['officialResult'];
    final displayName = (json['displayName'] as String?)?.trim();
    return TimeAttackSubmitResponse(
      runId: json['runId'] as String? ?? '',
      alreadyCompleted: json['alreadyCompleted'] as bool? ?? false,
      officialResult: TimeAttackOfficialResult.fromJson(
        official is Map
            ? Map<String, dynamic>.from(official)
            : <String, dynamic>{},
      ),
      displayName: displayName == null || displayName.isEmpty
          ? null
          : displayName,
    );
  }
}
