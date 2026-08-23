import 'package:flutter/material.dart';

import '../../data/firebase/time_attack_pending_submit_store.dart';
import '../../data/firebase/time_attack_run_remote_service.dart';
import '../../data/time_attack/default_time_attack_leaderboard_repository.dart';
import '../../data/time_attack/time_attack_leaderboard_repository.dart';
import '../../data/time_attack/time_attack_run_launcher.dart';
import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import '../../domain/time_attack/time_attack_run_api_models.dart';
import '../../domain/time_attack/time_attack_run_state.dart';
import '../widgets/time_attack_nickname_dialog.dart';
import '../widgets/time_attack_rank_style.dart';
import 'time_attack_game_screen.dart';
import 'time_attack_leaderboard_screen.dart';

class TimeAttackResultScreen extends StatefulWidget {
  final TimeAttackRunState runState;

  /// false のとき自己ベストを保存しない（DEBUG プレビュー用）
  final bool persistResult;

  /// Cloud Functions に紐づく runId（プレビュー時は null）
  final String? runId;

  const TimeAttackResultScreen({
    super.key,
    required this.runState,
    this.persistResult = true,
    this.runId,
  });

  @override
  State<TimeAttackResultScreen> createState() => _TimeAttackResultScreenState();
}

class _TimeAttackResultScreenState extends State<TimeAttackResultScreen>
    with SingleTickerProviderStateMixin {
  final _profile = TimeAttackLocalProfileService();
  final _remote = TimeAttackRunRemoteService();
  final _pendingStore = TimeAttackPendingSubmitStore();
  final TimeAttackLeaderboardRepository _leaderboardRepo =
      DefaultTimeAttackLeaderboardRepository();
  final _launcher = TimeAttackRunLauncher();

  late final AnimationController _blinkController;

  bool _processing = true;
  bool _isNewBest = false;
  bool _submitting = false;
  bool _submitFailed = false;
  bool _retrying = false;
  bool _editingName = false;
  bool _openingRanking = false;
  String? _nickname;
  String? _submitError;
  String? _retryError;
  TimeAttackLeaderboardSnapshot? _snapshot;

  TimeAttackRunState get runState => widget.runState;

  bool get _isAllClear => runState.endReason == TimeAttackEndReason.allClear;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _processResult();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  List<TimeAttackSubmitLevelResultPayload> _buildPayload() {
    return runState.results
        .map(
          (r) => TimeAttackSubmitLevelResultPayload(
            levelId: r.levelId,
            cleared: r.cleared,
            turnsUsed: r.turnsUsed,
            elapsedMs: r.elapsedMs,
            resetCount: r.resetCount,
          ),
        )
        .toList();
  }

  Future<void> _processResult() async {
    var isNewBest = false;
    if (widget.persistResult) {
      isNewBest = await _profile.tryUpdatePersonalBest(runState);
    }

    var submitFailed = false;
    String? submitError;
    if (widget.persistResult && widget.runId != null) {
      final payload = _buildPayload();
      try {
        final submitted = await _remote.submitRun(
          runId: widget.runId!,
          levelResults: payload,
        );
        await _pendingStore.clear();
        final assigned = submitted.displayName?.trim();
        if (assigned != null && assigned.isNotEmpty) {
          await _profile.saveConfirmedNickname(assigned);
        }
      } catch (e) {
        await _pendingStore.save(runId: widget.runId!, levelResults: payload);
        submitFailed = true;
        submitError = e is TimeAttackRunRemoteException
            ? e.message
            : 'ランキング送信に失敗しました';
      }
    }

    final nickname = await _resolveDisplayNickname();
    final snapshot = await _loadThisRunSnapshot(nickname);

    if (!mounted) return;
    setState(() {
      _isNewBest = isNewBest || (!widget.persistResult && runState.totalScore > 0);
      _nickname = nickname;
      _submitFailed = submitFailed;
      _submitError = submitError;
      _snapshot = snapshot;
      _processing = false;
    });

    if (isNewBest) {
      _blinkController.repeat(reverse: true);
    }
  }

  Future<void> _retrySubmit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final pending = await _pendingStore.load();
    final runId = pending?.runId ?? widget.runId;
    final payload = pending?.levelResults ?? _buildPayload();
    if (runId == null) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = '再送信できるデータがありません';
      });
      return;
    }

    try {
      final submitted = await _remote.submitRun(
        runId: runId,
        levelResults: payload,
      );
      await _pendingStore.clear();
      final assigned = submitted.displayName?.trim();
      if (assigned != null && assigned.isNotEmpty) {
        await _profile.saveConfirmedNickname(assigned);
      }
      final nickname = await _resolveDisplayNickname();
      final snapshot = await _loadThisRunSnapshot(nickname);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitFailed = false;
        _nickname = nickname;
        _snapshot = snapshot ?? _snapshot;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitFailed = true;
        _submitError = e is TimeAttackRunRemoteException
            ? e.message
            : 'ランキング送信に失敗しました';
      });
    }
  }

  Future<String> _resolveDisplayNickname() async {
    final resolved = await _profile.resolveNickname();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return (await _profile.getSavedNickname()) ?? '';
  }

  /// 結果画面の順位は自己ベストではなく「今回のスコアなら何位か」の仮表示のみ
  Future<TimeAttackLeaderboardSnapshot?> _loadThisRunSnapshot(
    String nickname,
  ) async {
    try {
      final base = await _leaderboardRepo.fetchLeaderboard();
      final meName = base.myEntry?.nickname.trim();
      if (meName != null && meName.isNotEmpty) {
        await _profile.saveConfirmedNickname(meName);
      }
      final displayName =
          (meName != null && meName.isNotEmpty) ? meName : nickname;
      if (displayName.isEmpty) return null;
      return _snapshotForThisRunRank(base, displayName);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editMyNickname() async {
    if (_editingName) return;
    setState(() => _editingName = true);
    try {
      final fromBoard = _snapshot?.myEntry?.nickname.trim();
      final current = (fromBoard != null && fromBoard.isNotEmpty)
          ? fromBoard
          : (await _profile.getSavedNickname()) ?? _nickname ?? '';
      if (!mounted) return;
      final taken = _snapshot?.rankedEntries
              .where((e) => !e.isMe)
              .map((e) => e.nickname) ??
          const <String>[];
      final ok = await showTimeAttackNicknameDialog(
        context,
        initialName: current,
        takenNames: taken,
      );
      if (!ok || !mounted) return;

      final nickname = (await _profile.getSavedNickname()) ?? current;
      final snapshot = await _loadThisRunSnapshot(nickname);
      if (!mounted) return;
      setState(() {
        _nickname = nickname;
        _snapshot = snapshot;
      });
    } finally {
      if (mounted) {
        setState(() => _editingName = false);
      } else {
        _editingName = false;
      }
    }
  }

  Future<void> _openRanking() async {
    if (_openingRanking || _retrying || _processing) return;
    setState(() => _openingRanking = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TimeAttackLeaderboardScreen(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingRanking = false);
      } else {
        _openingRanking = false;
      }
    }
  }

  Future<void> _retryChallenge() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _retryError = null;
    });

    try {
      final prepared = await _launcher.prepare();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TimeAttackGameScreen(
            sequence: prepared.sequence,
            runId: prepared.runId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _retrying = false;
        _retryError = e is TimeAttackRunRemoteException
            ? e.message
            : 'TIME ATTACKの開始には通信が必要です。';
      });
    }
  }

  /// 今回のラン分だけ差し込んだ仮スナップショット（結果画面専用・非永続）
  TimeAttackLeaderboardSnapshot _snapshotForThisRunRank(
    TimeAttackLeaderboardSnapshot base,
    String nickname,
  ) {
    final entries = base.rankedEntries.where((e) => !e.isMe).toList();
    entries.add(
      TimeAttackLeaderboardEntry(
        uid: 'this-run-me',
        nickname: nickname,
        clearCount: runState.clearCount,
        maxCombo: runState.maxCombo,
        comboBonus: runState.comboBonus,
        timeBonusPoints: runState.timeBonusPoints,
        achievedAt: DateTime.now(),
        isMe: true,
      ),
    );
    entries.sort((a, b) {
      final scoreCmp = b.totalScore.compareTo(a.totalScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.achievedAt.compareTo(b.achievedAt);
    });
    return TimeAttackLeaderboardSnapshot(rankedEntries: entries);
  }

  /// 自分を中心に前後最大3件（自分含む最大7件）
  List<({int rank, TimeAttackLeaderboardEntry entry})> _nearbyRanks() {
    final snapshot = _snapshot;
    if (snapshot == null) return const [];
    final index = snapshot.rankedEntries.indexWhere((e) => e.isMe);
    if (index < 0) return const [];
    final start = (index - 3).clamp(0, snapshot.rankedEntries.length);
    final end = (index + 4).clamp(0, snapshot.rankedEntries.length);
    final out = <({int rank, TimeAttackLeaderboardEntry entry})>[];
    for (var i = start; i < end; i++) {
      out.add((rank: i + 1, entry: snapshot.rankedEntries[i]));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムアタック', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildClearTitle(),
                        const SizedBox(height: 8),
                        if (_isNewBest) ...[
                          _buildNewRecordBlink(),
                          const SizedBox(height: 4),
                        ],
                        _buildTotalScore(),
                        const SizedBox(height: 10),
                        _buildBonusBreakdown(),
                        if (!_processing && _submitFailed) ...[
                          const SizedBox(height: 8),
                          Text(
                            _submitError ?? 'ランキング送信に失敗しました',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: _submitting ? null : _retrySubmit,
                            child: Text(_submitting ? '送信中…' : '再送信'),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildNearbyRanking(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: (_openingRanking || _retrying || _processing)
                      ? null
                      : _openRanking,
                  icon: _openingRanking
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFD54F),
                          ),
                        )
                      : const Icon(Icons.emoji_events, size: 18),
                  label: Text(
                    _openingRanking ? '読み込み中…' : 'ランキングを見る',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    side: const BorderSide(color: Color(0xFFFFD54F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                if (_retryError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _retryError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            (_retrying || _openingRanking)
                                ? null
                                : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '戻る',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (_retrying || _openingRanking) ? null : _retryChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _retrying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'リトライ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearTitle() {
    if (_isAllClear) {
      return const Text(
        'ALL CLEAR!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const Text(
      'CLEAR!',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF80DEEA),
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNewRecordBlink() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1).animate(
        CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
      ),
      child: const Text(
        'NEW RECORD!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTotalScore() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B46C1).withValues(alpha: 0.4),
            const Color(0xFF6B46C1).withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFB794F4).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL SCORE',
            style: TextStyle(
              color: Color(0xFFB794F4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${runState.totalScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusBreakdown() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'CLEAR',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '${runState.clearCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'CLEAR BONUS',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '+${runState.clearBonusPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'BONUS',
            style: TextStyle(
              color: Color(0xFFB794F4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _bonusRow('MAX COMBO', '×${runState.maxCombo}'),
          _bonusRow('COMBO BONUS', '+${runState.comboBonus}'),
          if (_isAllClear || runState.timeBonusPoints > 0)
            _bonusRow('TIME BONUS', '+${runState.timeBonusPoints}'),
        ],
      ),
    );
  }

  Widget _bonusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyRanking() {
    if (_processing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final nearby = _nearbyRanks();
    if (nearby.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          _nickname == null
              ? 'ランキング情報を取得できませんでした'
              : '今回のスコアで順位を計算できませんでした',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in nearby)
            _NearbyRankTile(
              rank: item.rank,
              entry: item.entry,
              onTapName: item.entry.isMe ? _editMyNickname : null,
            ),
        ],
      ),
    );
  }
}

class _NearbyRankTile extends StatelessWidget {
  const _NearbyRankTile({
    required this.rank,
    required this.entry,
    this.onTapName,
  });

  final int rank;
  final TimeAttackLeaderboardEntry entry;
  final VoidCallback? onTapName;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isMe;
    final rankAccent = TimeAttackRankStyle.accentColor(rank);
    final tint = TimeAttackRankStyle.rowTint(rank);
    const meNameColor = Color(0xFFB794F4);
    final nameColor = highlight ? meNameColor : Colors.white70;
    final scoreColor = TimeAttackRankStyle.isTop10(rank)
        ? rankAccent.withValues(alpha: 0.95)
        : Colors.white54;

    return Container(
      color: tint ?? Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: TimeAttackRankBadge(rank: rank, compact: true),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapName,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: nameColor,
                        fontSize: 13,
                        fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                        decoration:
                            onTapName != null ? TextDecoration.underline : null,
                        decorationColor: meNameColor,
                      ),
                    ),
                  ),
                  if (highlight) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit,
                      size: 12,
                      color: meNameColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Text(
            '${entry.totalScore}',
            style: TextStyle(
              color: scoreColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
