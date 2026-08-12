import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/challenge_level.dart';
import '../../domain/entities/challenge_progress.dart';
import '../../domain/services/challenge_level_loader.dart';
import '../providers/challenge_progress_notifier.dart';
import 'challenge_flow_scope.dart';
import 'challenge_game_screen.dart';
import 'challenge_stage_advance_result.dart';

/// チャレンジレベル選択画面
class ChallengeLevelSelectionScreen extends StatefulWidget {
  const ChallengeLevelSelectionScreen({super.key});

  @override
  State<ChallengeLevelSelectionScreen> createState() =>
      _ChallengeLevelSelectionScreenState();
}

class _ChallengeLevelSelectionScreenState
    extends State<ChallengeLevelSelectionScreen> {
  final ChallengeLevelLoader _loader = ChallengeLevelLoader();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stageKeys = {};
  final Map<int, ExpansionTileController> _stageControllers = {};

  List<ChallengeLevel> _levels = [];
  bool _isLoading = true;
  String? _error;
  bool _isHandlingStageAdvance = false;
  /// 次ステージ開始前にタップを促すレベル
  int? _highlightedLevel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final levels = await _loader.loadAllLevels();
      if (!mounted) return;
      await context.read<ChallengeProgressNotifier>().hydrate();

      if (!mounted) return;
      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressManager = context.watch<ChallengeProgressNotifier>().progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'チャレンジモード',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildContent(progressManager),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'エラーが発生しました',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ChallengeProgressManager progressManager) {
    if (_levels.isEmpty) {
      return const Center(
        child: Text(
          'レベルが見つかりません',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // ステージごとにグループ化
    final Map<int, List<ChallengeLevel>> stages = {};
    for (final level in _levels) {
      final stage = level.stageNumber;
      stages.putIfAbsent(stage, () => []).add(level);
    }

    final sortedStageNumbers = stages.keys.toList()..sort();
    final visibleStageNumbers = <int>[];
    var addedNextLockedStage = false;
    for (final stageNumber in sortedStageNumbers) {
      final isUnlocked = progressManager.isStageUnlocked(stageNumber);
      if (isUnlocked) {
        visibleStageNumbers.add(stageNumber);
      } else if (!addedNextLockedStage) {
        // 解放済みステージに続く、次の未解放ステージだけを予告表示する
        visibleStageNumbers.add(stageNumber);
        addedNextLockedStage = true;
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        for (final stageNumber in visibleStageNumbers)
          _buildStageCard(
            stageNumber,
            stages[stageNumber] ?? [],
            progressManager,
          ),
      ],
    );
  }

  Widget _buildStageCard(
    int stageNumber,
    List<ChallengeLevel> levels,
    ChallengeProgressManager progressManager,
  ) {
    final isUnlocked = progressManager.isStageUnlocked(stageNumber);
    final completedCount =
        progressManager.getCompletedLevelsInStage(stageNumber);
    final isPerfect = progressManager.isStagePerfect(stageNumber);
    final stageKey = _stageKeys.putIfAbsent(stageNumber, GlobalKey.new);
    final stageController = _stageControllers.putIfAbsent(
      stageNumber,
      ExpansionTileController.new,
    );

    return Card(
      key: stageKey,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1F3A).withOpacity(0.8),
      child: ExpansionTile(
        controller: stageController,
        title: Row(
          children: [
            Text(
              stageNumber == 0 ? 'ステージ 0' : 'ステージ $stageNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isPerfect) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.amber, size: 20),
            ],
          ],
        ),
        subtitle: Text(
          stageNumber == 0 &&
                  completedCount < levels.length &&
                  !progressManager.isStage0RequirementMet()
              ? '$completedCount / ${levels.length} クリア\n全クリアで他モード開放'
              : '$completedCount / ${levels.length} クリア',
          style: const TextStyle(color: Colors.white70),
        ),
        leading: Icon(
          isUnlocked ? Icons.lock_open : Icons.lock,
          color: isUnlocked ? Colors.green : Colors.grey,
        ),
        backgroundColor: const Color(0xFF1A1F3A).withOpacity(0.5),
        collapsedBackgroundColor: const Color(0xFF1A1F3A).withOpacity(0.5),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 画面サイズに応じて列数を計算
                // 最小サイズ: 60px（スター3つ + レベル番号 + パディング）
                // 最大サイズ: 80px
                const maxCellSize = 80.0;
                const spacing = 6.0;
                const padding = 32.0; // 左右のパディング

                final availableWidth = constraints.maxWidth - padding;
                final crossAxisCount =
                    (availableWidth / (maxCellSize + spacing)).floor().clamp(4, 10);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    return _buildLevelButton(level, progressManager);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(
    ChallengeLevel level,
    ChallengeProgressManager progressManager,
  ) {
    final isUnlocked = progressManager.isLevelUnlocked(level.level);
    final progress = progressManager.allProgress[level.level];
    final isCompleted = progress?.isCompleted ?? false;
    final stars = progress?.stars ?? 0;
    final isHighlighted = _highlightedLevel == level.level;

    return GestureDetector(
      onTap: isUnlocked ? () => _startLevel(level) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? (isCompleted
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A5568),
                        Color(0xFF2D3748),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D3748),
                        Color(0xFF1A202C),
                      ],
                    ))
              : null,
          color: isUnlocked ? null : const Color(0xFF1A202C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? Colors.lightBlueAccent
                : isUnlocked
                ? (isCompleted
                    ? Colors.green.withOpacity(0.6)
                    : Colors.blue.withOpacity(0.6))
                : Colors.grey.withOpacity(0.4),
            width: isHighlighted ? 3 : 1.5,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.lightBlueAccent.withOpacity(0.75),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ]
              : isUnlocked
              ? [
                  BoxShadow(
                    color: (isCompleted ? Colors.green : Colors.blue)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // メインコンテンツ
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // レベル番号
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      level.displayLabel,
                      style: TextStyle(
                        color: isUnlocked
                            ? (isCompleted ? Colors.white : Colors.white)
                            : Colors.grey.withOpacity(0.5),
                        fontSize: level.stageNumber == 0 ? 13 : 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // スター表示（完了時のみ）
                  if (isCompleted && stars > 0) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              index < stars ? Icons.star : Icons.star_border,
                              size: 12,
                              color: index < stars
                                  ? Colors.amber
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ロックアイコン（右上に配置）
            if (!isUnlocked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.grey,
                    size: 12,
                  ),
                ),
              ),
            // 完了バッジ（左上に配置）
            if (isCompleted && isUnlocked)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startLevel(ChallengeLevel level) async {
    ChallengeLevel? current = level;

    while (current != null && mounted) {
      final session = context.read<ChallengePlaySession>();
      final sessionFuture = session.arm();

      // push の Future は pushReplacement で途中完了するため待たない。
      // 選択へ戻るときはゲーム側が session.finish する。
      Navigator.push<Object?>(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeGameScreen(level: current!),
        ),
      );

      final result = await sessionFuture;

      if (!mounted) return;
      // ディスクと同期（Notifier はクリア時に既に更新済みだが、保険として再読込）
      await context.read<ChallengeProgressNotifier>().hydrate();
      if (!mounted) return;

      if (result is ChallengeStageAdvanceResult) {
        await _revealNextStage(result);
        if (!mounted) return;
        current = result.firstLevel;
        continue;
      }

      // OK / 戻る
      current = null;
    }
  }

  /// クリア済みステージ → 次ステージ → 先頭レベルの順に見せる
  Future<void> _revealNextStage(ChallengeStageAdvanceResult result) async {
    if (_isHandlingStageAdvance) return;
    _isHandlingStageAdvance = true;

    try {
      // ① 一度戻り、クリアしたステージ全体を0.8秒見せる
      await _showStageOverview(
        result.completedStageNumber,
        const Duration(milliseconds: 800),
      );
      if (!mounted) return;

      // ② 次のステージへ移り、全体を見せる
      await _scrollToAndOpenStage(
        result.nextStageNumber,
        const Duration(milliseconds: 400),
      );
      if (!mounted) return;

      // ③ 最初のレベルを0.4秒ハイライトしてタップを促す
      setState(() {
        _highlightedLevel = result.firstLevel.level;
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _highlightedLevel = null;
        });
      }
      _isHandlingStageAdvance = false;
    }
  }

  Future<void> _showStageOverview(
    int stageNumber,
    Duration displayDuration,
  ) async {
    setState(() {
      _highlightedLevel = null;
    });

    _collapseOtherStages(stageNumber);
    _stageControllers[stageNumber]?.expand();

    // 展開アニメーション後に対象ステージへ寄せる
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    await _scrollToStage(stageNumber);
    await Future<void>.delayed(displayDuration);
  }

  /// 閉じた次ステージへスクロールしてから、カードを展開する
  Future<void> _scrollToAndOpenStage(
    int stageNumber,
    Duration displayDuration,
  ) async {
    setState(() {
      _highlightedLevel = null;
    });

    _collapseOtherStages(stageNumber);
    _stageControllers[stageNumber]?.collapse();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    await _scrollToStage(stageNumber);
    if (!mounted) return;

    _stageControllers[stageNumber]?.expand();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    await Future<void>.delayed(displayDuration);
  }

  void _collapseOtherStages(int stageNumber) {
    for (final entry in _stageControllers.entries) {
      if (entry.key != stageNumber) {
        entry.value.collapse();
      }
    }
  }

  Future<void> _scrollToStage(int stageNumber) async {
    final stageContext = _stageKeys[stageNumber]?.currentContext;
    if (stageContext != null) {
      await Scrollable.ensureVisible(
        stageContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }
}
