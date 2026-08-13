import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import '../firebase/firebase_bootstrap.dart';
import 'time_attack_leaderboard_repository.dart';

/// `leaderboards/global` を one-shot get する本番実装
class FirestoreTimeAttackLeaderboardRepository
    implements TimeAttackLeaderboardRepository {
  FirestoreTimeAttackLeaderboardRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _docPath = 'leaderboards/global';

  static const _opTimeout = Duration(seconds: 10);

  @override
  Future<TimeAttackLeaderboardSnapshot> fetchLeaderboard() async {
    await _ensureAuth().timeout(_opTimeout);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Firestore leaderboard requires signed-in user');
    }

    final snap = await _firestore.doc(_docPath).get().timeout(_opTimeout);
    final data = snap.data();
    final rawEntries = (data?['entries'] as List<dynamic>?) ?? const [];

    final entries = <TimeAttackLeaderboardEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final entryUid = (map['uid'] as String?)?.trim() ?? '';
      if (entryUid.isEmpty) continue;
      final achievedRaw = map['achievedAt'];
      DateTime achievedAt;
      if (achievedRaw is Timestamp) {
        achievedAt = achievedRaw.toDate();
      } else if (achievedRaw is String) {
        achievedAt = DateTime.tryParse(achievedRaw) ?? DateTime.now();
      } else {
        achievedAt = DateTime.now();
      }

      entries.add(
        TimeAttackLeaderboardEntry(
          uid: entryUid,
          nickname: (map['name'] as String?)?.trim().isNotEmpty == true
              ? (map['name'] as String).trim()
              : 'Player',
          clearCount: (map['clearCount'] as num?)?.toInt() ?? 0,
          maxCombo: (map['maxCombo'] as num?)?.toInt() ?? 0,
          comboBonus: (map['comboBonus'] as num?)?.toInt() ?? 0,
          timeBonusPoints: (map['timeBonus'] as num?)?.toInt() ?? 0,
          achievedAt: achievedAt,
          isMe: entryUid == uid,
        ),
      );
    }

    entries.sort(_compareEntries);

    final hasMe = entries.any((e) => e.isMe);
    if (!hasMe) {
      final synthetic = await _syntheticMeFromUserDoc(uid);
      if (synthetic != null) {
        entries.add(synthetic);
        entries.sort(_compareEntries);
      }
    }

    final limited = entries.take(1000).toList();
    // TOP1000 に入れなかった自分はフッター用にだけ末尾へ（myRank=null → 1000+）
    if (!limited.any((e) => e.isMe) && entries.any((e) => e.isMe)) {
      limited.add(entries.firstWhere((e) => e.isMe));
    }

    return TimeAttackLeaderboardSnapshot(rankedEntries: limited);
  }

  static int _compareEntries(
    TimeAttackLeaderboardEntry a,
    TimeAttackLeaderboardEntry b,
  ) {
    final scoreCmp = b.totalScore.compareTo(a.totalScore);
    if (scoreCmp != 0) return scoreCmp;
    return a.achievedAt.compareTo(b.achievedAt);
  }

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseBootstrap.signInAnonymously();
  }

  Future<TimeAttackLeaderboardEntry?> _syntheticMeFromUserDoc(String uid) async {
    try {
      final userSnap = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(_opTimeout);
      final data = userSnap.data();
      if (data == null) return null;
      final bestScore = (data['bestTotalScore'] as num?)?.toInt();
      if (bestScore == null || bestScore <= 0) return null;

      final achievedRaw = data['bestAchievedAt'];
      DateTime achievedAt;
      if (achievedRaw is Timestamp) {
        achievedAt = achievedRaw.toDate();
      } else if (achievedRaw is String) {
        achievedAt = DateTime.tryParse(achievedRaw) ?? DateTime.now();
      } else {
        achievedAt = DateTime.now();
      }

      return TimeAttackLeaderboardEntry(
        uid: uid,
        nickname: (data['displayName'] as String?)?.trim().isNotEmpty == true
            ? (data['displayName'] as String).trim()
            : 'Player',
        clearCount: (data['bestClearCount'] as num?)?.toInt() ?? 0,
        maxCombo: (data['bestMaxCombo'] as num?)?.toInt() ?? 0,
        comboBonus: (data['bestComboBonus'] as num?)?.toInt() ?? 0,
        timeBonusPoints: (data['bestTimeBonus'] as num?)?.toInt() ?? 0,
        achievedAt: achievedAt,
        isMe: true,
      );
    } catch (_) {
      return null;
    }
  }
}
