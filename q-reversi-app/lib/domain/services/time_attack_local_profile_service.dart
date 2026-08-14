import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase/time_attack_player_remote_service.dart';
import '../../data/firebase/time_attack_run_remote_service.dart';
import '../time_attack/ng_word_list.dart';
import '../time_attack/time_attack_personal_best.dart';
import '../time_attack/time_attack_player_identity.dart';
import '../time_attack/time_attack_run_state.dart';

enum NicknameSetResult { ok, invalid, taken, blocked, failed }

/// UID・ニックネーム・自己ベストのローカル保存
///
/// 識別子は Firebase Anonymous Auth の UID。未初期化時のみローカルUID。
class TimeAttackLocalProfileService {
  static const String _uidKey = 'time_attack_local_uid';
  static const String _nicknameKey = 'time_attack_player_name';
  static const String _personalBestKey = 'time_attack_personal_best';

  static const int minNicknameLength = 1;
  static const int maxNicknameLength =
      TimeAttackPlayerIdentity.maxPlayerNameLength;

  /// 内部UID。表示名には使わない。
  Future<String> getLocalUid() async {
    final authUid = _firebaseUid();
    if (authUid != null) return authUid;
    return _fallbackLocalUid();
  }

  String? _firebaseUid() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (uid == null || uid.isEmpty) return null;
      return uid;
    } catch (_) {
      return null;
    }
  }

  Future<String> _fallbackLocalUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_uidKey)?.trim();
      if (existing != null && existing.isNotEmpty) return existing;
      final uid = TimeAttackPlayerIdentity.generateLocalUid();
      await prefs.setString(_uidKey, uid);
      return uid;
    } catch (_) {
      return TimeAttackPlayerIdentity.generateLocalUid();
    }
  }

  /// 保存済みの名前。未割当なら null。
  Future<String?> getSavedNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_nicknameKey)?.trim();
      if (raw == null || raw.isEmpty) return null;
      return raw;
    } catch (_) {
      return null;
    }
  }

  /// 保存済みならそれ。なければ taken を避けて QMasterN を割り当てて保存する。
  Future<String> getOrAssignNickname({
    Iterable<String> takenNames = const [],
  }) async {
    final saved = await getSavedNickname();
    if (saved != null) return saved;

    final name = TimeAttackPlayerIdentity.nextDefaultNickname(takenNames);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nicknameKey, name);
    } catch (_) {}
    return name;
  }

  Future<String> getNickname() => getOrAssignNickname();

  Future<String> getDisplayNickname() => getOrAssignNickname();

  Future<NicknameSetResult> setNickname(
    String raw, {
    Iterable<String> takenNames = const [],
    bool syncRemote = true,
  }) async {
    final validated = validateNickname(raw);
    if (validated == null) return NicknameSetResult.invalid;
    if (NgWordList.containsNgWord(validated)) {
      return NicknameSetResult.blocked;
    }

    final current = await getSavedNickname();
    if (TimeAttackPlayerIdentity.isTaken(
      validated,
      takenNames: takenNames,
      allowedCurrent: current,
    )) {
      return NicknameSetResult.taken;
    }

    var nameToSave = validated;
    if (syncRemote) {
      try {
        nameToSave =
            await TimeAttackPlayerRemoteService().setPlayerName(validated);
      } on TimeAttackRunRemoteException catch (e) {
        final msg = e.message;
        if (msg.contains('すでに使われています')) {
          return NicknameSetResult.taken;
        }
        if (msg.contains('使用できない言葉')) {
          return NicknameSetResult.blocked;
        }
        return NicknameSetResult.failed;
      } catch (_) {
        return NicknameSetResult.failed;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nicknameKey, nameToSave);
      return NicknameSetResult.ok;
    } catch (_) {
      return NicknameSetResult.failed;
    }
  }

  /// trim後 1〜12文字。空・改行・制御文字は不可。OKなら正規化文字列、NGなら null
  static String? validateNickname(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < minNicknameLength ||
        trimmed.length > maxNicknameLength) {
      return null;
    }
    for (final code in trimmed.codeUnits) {
      if (code == 0x0A || code == 0x0D) return null;
      if (code < 0x20 || code == 0x7F) return null;
    }
    return trimmed;
  }

  Future<TimeAttackPersonalBest?> getPersonalBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_personalBestKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TimeAttackPersonalBest.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// 自己ベストを更新できたら true（同点以下は更新しない）
  Future<bool> tryUpdatePersonalBest(TimeAttackRunState runState) async {
    await getLocalUid();
    await getOrAssignNickname();

    final candidate = TimeAttackPersonalBest(
      clearCount: runState.clearCount,
      maxCombo: runState.maxCombo,
      comboBonus: runState.comboBonus,
      timeBonusPoints: runState.timeBonusPoints,
      totalScore: runState.totalScore,
      achievedAt: DateTime.now(),
    );

    final current = await getPersonalBest();
    if (current != null && !current.isBeatenBy(candidate)) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _personalBestKey,
        jsonEncode(candidate.toJson()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ランキング関連の端末内データ（表示名・自己ベスト・ローカルUID）を消す
  Future<void> clearRankingLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nicknameKey);
      await prefs.remove(_personalBestKey);
      await prefs.remove(_uidKey);
    } catch (_) {}
  }
}
