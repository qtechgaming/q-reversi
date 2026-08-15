import 'package:flutter/material.dart';

import '../../data/time_attack/default_time_attack_leaderboard_repository.dart';
import '../../data/time_attack/time_attack_leaderboard_repository.dart';
import '../../domain/services/time_attack_local_profile_service.dart';
import '../../domain/time_attack/time_attack_leaderboard_entry.dart';
import '../widgets/time_attack_nickname_dialog.dart';
import '../widgets/time_attack_rank_style.dart';

class TimeAttackLeaderboardScreen extends StatefulWidget {
  const TimeAttackLeaderboardScreen({
    super.key,
    this.repository,
  });

  final TimeAttackLeaderboardRepository? repository;

  @override
  State<TimeAttackLeaderboardScreen> createState() =>
      _TimeAttackLeaderboardScreenState();
}

class _TimeAttackLeaderboardScreenState
    extends State<TimeAttackLeaderboardScreen> {
  late final TimeAttackLeaderboardRepository _repository;
  final _listController = ScrollController();
  final _myTileKey = GlobalKey();

  TimeAttackLeaderboardSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;

  /// 行（padding込み）+ separator のおおよその高さ
  static const _rowStride = 49.0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? DefaultTimeAttackLeaderboardRepository();
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

  void _scheduleScrollToMe(TimeAttackLeaderboardSnapshot snapshot) {
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
    // まず付近まで飛ばして自分の行をビルドさせる
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

    // キー未取得時は概算位置へアニメーション
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
    final current = await profile.resolveNickname() ??
        _snapshot?.myEntry?.nickname ??
        '';
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

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  void _showEntryDetail(TimeAttackLeaderboardEntry entry, int rank) {
    final dateText = _formatDateTime(entry.achievedAt);
    final rankLabel = rank > 0 ? '#$rank' : '—';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      rankLabel,
                      style: TextStyle(
                        color: entry.isMe
                            ? const Color(0xFFB794F4)
                            : Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.nickname,
                        style: TextStyle(
                          color: entry.isMe
                              ? const Color(0xFFB794F4)
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (entry.isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Color(0xFFB794F4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'TOTAL SCORE  ${entry.totalScore}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                _detailRow('CLEAR数', '${entry.clearCount}'),
                _detailRow('MAX COMBO', '×${entry.maxCombo}'),
                _detailRow('COMBO BONUS', '+${entry.comboBonus}'),
                if (entry.timeBonusPoints > 0)
                  _detailRow('TIME BONUS', '+${entry.timeBonusPoints}'),
                _detailRow('更新日時', dateText),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング', style: TextStyle(color: Colors.white)),
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
              const Text(
                'ランキングを読み込めませんでした',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
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
                'TOTAL SCORE',
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
                onTap: () => _showEntryDetail(entry, rank),
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
    required TimeAttackLeaderboardEntry? myEntry,
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
            onTap: () => _showEntryDetail(myEntry, myRank ?? 0),
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
    required this.onTap,
    this.emphasizeMe = false,
    this.outOfListLabel,
    this.onTapName,
  });

  static const _meNameColor = Color(0xFFB794F4);

  final int rank;
  final TimeAttackLeaderboardEntry entry;
  final VoidCallback onTap;
  final bool emphasizeMe;

  /// 一覧外フッター用（順位バッジの代わりに表示）
  final String? outOfListLabel;
  final VoidCallback? onTapName;

  @override
  Widget build(BuildContext context) {
    final rankAccent = rank > 0
        ? TimeAttackRankStyle.accentColor(rank)
        : Colors.white54;
    final tint = rank > 0 ? TimeAttackRankStyle.rowTint(rank) : null;
    final nameColor = emphasizeMe ? _meNameColor : Colors.white;
    final scoreColor = TimeAttackRankStyle.isTop10(rank)
        ? rankAccent.withValues(alpha: 0.95)
        : Colors.white70;

    return InkWell(
      onTap: onTap,
      child: Container(
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
                          fontWeight: emphasizeMe
                              ? FontWeight.bold
                              : FontWeight.w500,
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
              '${entry.totalScore}',
              style: TextStyle(
                color: scoreColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
