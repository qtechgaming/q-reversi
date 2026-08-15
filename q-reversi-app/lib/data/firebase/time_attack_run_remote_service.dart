import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/time_attack/time_attack_run_api_models.dart';
import 'firebase_bootstrap.dart';

class TimeAttackRunRemoteException implements Exception {
  final String message;
  TimeAttackRunRemoteException(this.message);

  @override
  String toString() => message;
}

/// Cloud Functions 経由の TIME ATTACK start/submit
class TimeAttackRunRemoteService {
  TimeAttackRunRemoteService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  Future<void> _ensureAuth() async {
    await FirebaseBootstrap.ensureSignedIn();
    if (FirebaseAuth.instance.currentUser == null) {
      throw TimeAttackRunRemoteException(
        'TIME ATTACKの開始には通信が必要です。',
      );
    }
  }

  Future<TimeAttackStartResponse> startRun() async {
    await _ensureAuth();
    try {
      final callable = _functions.httpsCallable('startTimeAttackRun');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      return TimeAttackStartResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      throw TimeAttackRunRemoteException(
        e.message?.isNotEmpty == true
            ? e.message!
            : 'TIME ATTACKの開始には通信が必要です。',
      );
    } catch (_) {
      throw TimeAttackRunRemoteException(
        'TIME ATTACKの開始には通信が必要です。',
      );
    }
  }

  Future<TimeAttackSubmitResponse> submitRun({
    required String runId,
    required List<TimeAttackSubmitLevelResultPayload> levelResults,
  }) async {
    await _ensureAuth();
    try {
      final callable = _functions.httpsCallable('submitTimeAttackRun');
      final result = await callable.call(<String, dynamic>{
        'runId': runId,
        'levelResults': levelResults.map((e) => e.toJson()).toList(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return TimeAttackSubmitResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      throw TimeAttackRunRemoteException(
        e.message?.isNotEmpty == true
            ? e.message!
            : 'ランキング送信に失敗しました',
      );
    } catch (_) {
      throw TimeAttackRunRemoteException('ランキング送信に失敗しました');
    }
  }
}
