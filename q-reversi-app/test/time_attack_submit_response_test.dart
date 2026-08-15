import 'package:flutter_test/flutter_test.dart';
import 'package:q_reversi_app/domain/time_attack/time_attack_run_api_models.dart';

void main() {
  test('submit response keeps server displayName', () {
    final response = TimeAttackSubmitResponse.fromJson({
      'runId': 'run-1',
      'alreadyCompleted': false,
      'displayName': 'QMaster2',
      'officialResult': {
        'finishReason': 'allClear',
        'clearCount': 3,
        'perfectCount': 1,
        'maxCombo': 2,
        'comboBonus': 10,
        'timeBonus': 20,
        'clearBonus': 30,
        'totalScore': 60,
        'remainingTimeMs': 1000,
      },
    });

    expect(response.displayName, 'QMaster2');
    expect(response.runId, 'run-1');
  });

  test('submit response treats blank displayName as null', () {
    final response = TimeAttackSubmitResponse.fromJson({
      'runId': 'run-1',
      'alreadyCompleted': true,
      'displayName': '  ',
      'officialResult': <String, dynamic>{},
    });

    expect(response.displayName, isNull);
  });
}
