import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/time_attack/time_attack_run_api_models.dart';

/// submit 失敗時の再送用
class TimeAttackPendingSubmitStore {
  static const _key = 'time_attack_pending_submit_v1';

  Future<void> save({
    required String runId,
    required List<TimeAttackSubmitLevelResultPayload> levelResults,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'runId': runId,
        'levelResults': levelResults.map((e) => e.toJson()).toList(),
      }),
    );
  }

  Future<({String runId, List<TimeAttackSubmitLevelResultPayload> levelResults})?>
      load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final runId = map['runId'] as String?;
      final list = map['levelResults'];
      if (runId == null || list is! List) return null;
      final results = <TimeAttackSubmitLevelResultPayload>[];
      for (final item in list) {
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        results.add(
          TimeAttackSubmitLevelResultPayload(
            levelId: (row['levelId'] as num).toInt(),
            cleared: row['cleared'] as bool? ?? false,
            turnsUsed: (row['turnsUsed'] as num?)?.toInt() ?? 0,
            elapsedMs: (row['elapsedMs'] as num?)?.toInt() ?? 0,
            resetCount: (row['resetCount'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      return (runId: runId, levelResults: results);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
