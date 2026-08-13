import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/game_mode.dart';
import '../../domain/services/vs_cpu_progress_service.dart';
import '../../domain/vs/vs_quantum_leaderboard_entry.dart';
import '../firebase/firebase_bootstrap.dart';
import '../firebase/vs_quantum_remote_service.dart';
import 'vs_quantum_leaderboard_repository.dart';

/// 入場時にローカル勝ち数を sync し、`leaderboards/vs_quantum` を one-shot get
class FirestoreVsQuantumLeaderboardRepository
    implements VsQuantumLeaderboardRepository {
  FirestoreVsQuantumLeaderboardRepository({
    FirebaseFirestore? firestore,
    VsQuantumRemoteService? remote,
    VsCpuProgressService? progressService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _remote = remote ?? VsQuantumRemoteService(),
        _progress = progressService ?? VsCpuProgressService();

  final FirebaseFirestore _firestore;
  final VsQuantumRemoteService _remote;
  final VsCpuProgressService _progress;

  static const _docPath = 'leaderboards/vs_quantum';

  static const _opTimeout = Duration(seconds: 10);

  @override
  Future<VsQuantumLeaderboardSnapshot> fetchLeaderboard() async {
    await _ensureAuth().timeout(_opTimeout);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('VS leaderboard requires signed-in user');
    }

    final localSnap = await _progress.load();
    final localWins =
        (localSnap.stats[AIDifficulty.quantum] ?? const VsCpuStats()).wins;
    if (localWins > 0) {
      // sync 失敗・ハングでも一覧表示は続行する
      try {
        await _remote.syncWins(localWins).timeout(_opTimeout);
      } catch (e) {
        debugPrint('VS quantum syncWins skipped: $e');
      }
    }

    final snap = await _firestore.doc(_docPath).get().timeout(_opTimeout);
    final data = snap.data();
    final rawEntries = (data?['entries'] as List<dynamic>?) ?? const [];

    final entries = <VsQuantumLeaderboardEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final entryUid = (map['uid'] as String?)?.trim() ?? '';
      if (entryUid.isEmpty) continue;

      entries.add(
        VsQuantumLeaderboardEntry(
          uid: entryUid,
          nickname: (map['name'] as String?)?.trim().isNotEmpty == true
              ? (map['name'] as String).trim()
              : 'Player',
          wins: (map['wins'] as num?)?.toInt() ?? 0,
          achievedAt: _parseAchievedAt(map['achievedAt']),
          isMe: entryUid == uid,
        ),
      );
    }

    entries.sort(_compareEntries);

    final hasMe = entries.any((e) => e.isMe);
    if (!hasMe) {
      final synthetic = await _syntheticMeFromUserDoc(uid, localWins);
      if (synthetic != null) {
        entries.add(synthetic);
        entries.sort(_compareEntries);
      }
    }

    final limited = entries.take(1000).toList();
    if (!limited.any((e) => e.isMe) && entries.any((e) => e.isMe)) {
      limited.add(entries.firstWhere((e) => e.isMe));
    }

    return VsQuantumLeaderboardSnapshot(rankedEntries: limited);
  }

  static int _compareEntries(
    VsQuantumLeaderboardEntry a,
    VsQuantumLeaderboardEntry b,
  ) {
    final winCmp = b.wins.compareTo(a.wins);
    if (winCmp != 0) return winCmp;
    return a.achievedAt.compareTo(b.achievedAt);
  }

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseBootstrap.signInAnonymously();
  }

  DateTime _parseAchievedAt(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Future<VsQuantumLeaderboardEntry?> _syntheticMeFromUserDoc(
    String uid,
    int localWins,
  ) async {
    try {
      final userSnap = await _firestore.collection('users').doc(uid).get();
      final data = userSnap.data();
      final serverWins = (data?['vsQuantumWins'] as num?)?.toInt() ?? 0;
      final wins = serverWins > localWins ? serverWins : localWins;
      if (wins <= 0) return null;

      return VsQuantumLeaderboardEntry(
        uid: uid,
        nickname: (data?['displayName'] as String?)?.trim().isNotEmpty == true
            ? (data!['displayName'] as String).trim()
            : 'Player',
        wins: wins,
        achievedAt: _parseAchievedAt(data?['vsQuantumAchievedAt']),
        isMe: true,
      );
    } catch (_) {
      if (localWins <= 0) return null;
      return VsQuantumLeaderboardEntry(
        uid: uid,
        nickname: 'Player',
        wins: localWins,
        achievedAt: DateTime.now(),
        isMe: true,
      );
    }
  }
}
