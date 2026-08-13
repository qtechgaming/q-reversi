import 'package:flutter/material.dart';

import '../../data/vs/default_vs_quantum_leaderboard_repository.dart';
import '../../data/vs/vs_quantum_leaderboard_repository.dart';
import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/vs/vs_quantum_leaderboard_entry.dart';
import '../widgets/time_attack_nickname_dialog.dart';
import '../widgets/time_attack_rank_style.dart';

class VsQuantumLeaderboardScreen extends StatefulWidget {
  const VsQuantumLeaderboardScreen({
    super.key,
    this.repository,
  });

  final VsQuantumLeaderboardRepository? repository;

  @override
  State<VsQuantumLeaderboardScreen> createState() =>
      _VsQuantumLeaderboardScreenState();
}

class _VsQuantumLeaderboardScreenState
    extends State<VsQuantumLeaderboardScreen> {
  late final VsQuantumLeaderboardRepository _repository;
  final _listController = ScrollController();
  final _myTileKey = GlobalKey();

  VsQuantumLeaderboardSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;

  static const _rowStride = 49.0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? DefaultVsQuantumLeaderboardRepository();
    _load();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _repository.fetchLeaderboard();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
      _scheduleScrollToMe(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _scheduleScrollToMe(VsQuantumLeaderboardSnapshot snapshot) {
    final myRank = snapshot.myRank;
    if (myRank == null || myRank < 1 || myRank > snapshot.displayLimit) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToRank(myRank);
    });
  }

  Future<void> _scrollToRank(int rank) async {
    if (!mounted || !_listController.hasClients) return;

    final position = _listController.position;
    final rough = ((rank - 1) * _rowStride)
        .clamp(0.0, position.maxScrollExtent);
    _listController.jumpTo(rough);

    await Future<void>.delayed(const Duration(milliseconds: 32));
    if (!mounted) return;

    final ctx = _myTileKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.35,
      );
      return;
    }

    if (!_listController.hasClients) return;
    final viewport = _listController.position.viewportDimension;
    final target = (((rank - 1) * _rowStride) - viewport * 0.35)
        .clamp(0.0, _listController.position.maxScrollExtent);
    await _listController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _editNickname() async {
    final profile = TimeAttackLocalProfileService();
    final current = await profile.getNickname();
    if (!mounted) return;
    final ok = await showTimeAttackNicknameDialog(
      context,
      initialName: current,
      takenNames: _snapshot?.rankedEntries
              .where((e) => !e.isMe)
              .map((e) => e.nickname) ??
          const [],
      title: 'プレイヤー名を変更',
      confirmLabel: '保存',
    );
    if (ok && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VS量子AI RANKING', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'プレイヤー名',
            onPressed: _loading ? null : _editNickname,
            icon: const Icon(Icons.badge_outlined),
          ),
          IconButton(
            tooltip: '更新',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '読み込みに失敗しました\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final top = snapshot.topDisplayEntries;
    final myEntry = snapshot.myEntry;
    final myRank = snapshot.myRank;
    final inDisplayedList =
        myEntry != null && myRank != null && myRank <= snapshot.displayLimit;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '#',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'ニックネーム',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              Text(
                '勝利数',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: ListView.separated(
            controller: _listController,
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: top.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final entry = top[index];
              final rank = index + 1;
              final tile = _RankTile(
                rank: rank,
                entry: entry,
                emphasizeMe: entry.isMe,
                onTapName: entry.isMe ? _editNickname : null,
              );
              if (entry.isMe) {
                return KeyedSubtree(key: _myTileKey, child: tile);
              }
              return tile;
            },
          ),
        ),
        if (!inDisplayedList)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildOutOfListFooter(
              myEntry: myEntry,
              myRank: myRank,
            ),
          ),
      ],
    );
  }

  Widget _buildOutOfListFooter({
    required VsQuantumLeaderboardEntry? myEntry,
    required int? myRank,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(
            '〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (myEntry == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'あなたの記録はまだありません',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          _RankTile(
            rank: myRank ?? 0,
            entry: myEntry,
            emphasizeMe: true,
            outOfListLabel: myRank == null ? '1000+' : null,
            onTapName: _editNickname,
          ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.entry,
    this.emphasizeMe = false,
    this.outOfListLabel,
    this.onTapName,
  });

  static const _meNameColor = Color(0xFFB794F4);

  final int rank;
  final VsQuantumLeaderboardEntry entry;
  final bool emphasizeMe;
  final String? outOfListLabel;
  final VoidCallback? onTapName;

  @override
  Widget build(BuildContext context) {
    final rankAccent = rank > 0
        ? TimeAttackRankStyle.accentColor(rank)
        : Colors.white54;
    final tint = rank > 0 ? TimeAttackRankStyle.rowTint(rank) : null;
    final nameColor = emphasizeMe ? _meNameColor : Colors.white;
    final winsColor = TimeAttackRankStyle.isTop10(rank)
        ? rankAccent.withValues(alpha: 0.95)
        : Colors.white70;

    return Container(
      color: tint ?? Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: outOfListLabel != null
                ? Text(
                    outOfListLabel!,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight:
                          emphasizeMe ? FontWeight.bold : FontWeight.w500,
                    ),
                  )
                : TimeAttackRankBadge(rank: rank),
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
                        fontSize: 15,
                        fontWeight:
                            emphasizeMe ? FontWeight.bold : FontWeight.w500,
                        decoration:
                            emphasizeMe ? TextDecoration.underline : null,
                        decorationColor: nameColor,
                        decorationThickness: emphasizeMe ? 1.6 : null,
                      ),
                    ),
                  ),
                  if (emphasizeMe) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit,
                      size: 14,
                      color: _meNameColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Text(
            '${entry.wins}',
            style: TextStyle(
              color: winsColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
