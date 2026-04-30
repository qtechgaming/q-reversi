import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/challenge_level.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/challenge_progress.dart';
import '../../domain/entities/board.dart';
import '../../domain/services/challenge_game_service.dart';
import '../../domain/services/challenge_level_loader.dart';
import '../providers/challenge_progress_notifier.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/gate_button.dart';

/// チャレンジゲーム画面
class ChallengeGameScreen extends StatefulWidget {
  final ChallengeLevel level;

  const ChallengeGameScreen({
    super.key,
    required this.level,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _GuideStep {
  final GlobalKey key;
  final String message;

  const _GuideStep({
    required this.key,
    required this.message,
  });
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  static const String _challengeGuideShownKey = 'challenge_play_guide_shown';
  GateType? _selectedGate;
  List<Position> _selectedPositions = [];
  int? _selectedRow;
  int? _selectedColumn;
  String? _entangledErrorMessage;
  double _horizontalDragOffset = 0;
  bool _isSwipeNavigating = false;
  List<ChallengeLevel> _allLevels = const [];
  int _guideStepIndex = 0;
  List<_GuideStep> _guideSteps = const [];
  final GlobalKey _goalConditionKey = GlobalKey();
  final GlobalKey _xGateButtonKey = GlobalKey();
  final GlobalKey _boardAreaKey = GlobalKey();
  final GlobalKey _applyGateButtonKey = GlobalKey();
  final GlobalKey _gateInfoButtonKey = GlobalKey();
  OverlayEntry? _guideOverlay;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimationListener;

  final ChallengeGameService _challengeService = ChallengeGameService();
  final ChallengeLevelLoader _levelLoader = ChallengeLevelLoader();

  @override
  void initState() {
    super.initState();
    _loadSwipePreviewData();
    _maybeShowGuide();
  }

  @override
  void dispose() {
    if (_routeAnimationListener != null && _routeAnimation != null) {
      _routeAnimation!.removeStatusListener(_routeAnimationListener!);
    }
    _routeAnimation = null;
    _routeAnimationListener = null;
    _guideOverlay?.remove();
    _guideOverlay = null;
    super.dispose();
  }

  Future<void> _loadSwipePreviewData() async {
    final levels = await _levelLoader.loadAllLevels();
    if (!mounted) return;
    setState(() {
      _allLevels = levels;
    });
  }

  Future<void> _maybeShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final isShown = prefs.getBool(_challengeGuideShownKey) ?? false;
    if (isShown || !mounted) return;

    await prefs.setBool(_challengeGuideShownKey, true);
    _startGuideAfterRouteTransition();
  }

  void _startGuideAfterRouteTransition() {
    if (!mounted) return;

    final routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation = routeAnimation;
    if (routeAnimation == null || routeAnimation.status == AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startGuideOverlay();
      });
      return;
    }

    _routeAnimationListener = (status) {
      if (status != AnimationStatus.completed || !mounted) return;
      routeAnimation.removeStatusListener(_routeAnimationListener!);
      _routeAnimationListener = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startGuideOverlay();
      });
    };
    routeAnimation.addStatusListener(_routeAnimationListener!);
  }

  void _startGuideOverlay() {
    _guideSteps = [
      _GuideStep(
        key: _goalConditionKey,
        message: '1. クリア条件を確認してください。\n盤面をすべて白にするか、黒にしたらレベルクリアです',
      ),
      _GuideStep(
        key: _xGateButtonKey,
        message: '2. ゲートを選択してください',
      ),
      _GuideStep(
        key: _boardAreaKey,
        message: '3. 適用する駒を選択してください。\n盤面の中をタップか、盤面の外のボタンをタップしてください',
      ),
      _GuideStep(
        key: _applyGateButtonKey,
        message: '4. "ゲートを適用"ボタンでゲートを駒に適用させて下さい',
      ),
      _GuideStep(
        key: _gateInfoButtonKey,
        message: '5. いつでもこのinfoボタンから、ゲートの効果を確認できます',
      ),
    ];
    _guideStepIndex = 0;
    _showGuideStep();
  }

  void _showGuideStep() {
    if (!mounted) return;
    if (_guideStepIndex >= _guideSteps.length) {
      _hideGuideOverlay();
      return;
    }

    final targetRect = _targetRect(_guideSteps[_guideStepIndex].key);
    if (targetRect == null) {
      _guideStepIndex++;
      _showGuideStep();
      return;
    }

    final overlay = Overlay.of(context);
    _guideOverlay?.remove();
    _guideOverlay = OverlayEntry(
      builder: (_) => _buildGuideOverlay(targetRect),
    );
    overlay.insert(_guideOverlay!);
  }

  Rect? _targetRect(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  Widget _buildGuideOverlay(Rect targetRect) {
    final screenSize = MediaQuery.of(context).size;
    final center = targetRect.center;
    const bubbleWidth = 300.0;
    const bubbleHeight = 132.0;
    final left = (center.dx - bubbleWidth / 2)
        .clamp(12.0, screenSize.width - bubbleWidth - 12.0)
        .toDouble();
    final top = (targetRect.bottom + 12.0 + bubbleHeight < screenSize.height)
        ? (targetRect.bottom + 12.0)
        : (targetRect.top - bubbleHeight - 12.0);
    final isBubbleAbove = top < targetRect.top;
    final connectorX = (center.dx - left).clamp(14.0, bubbleWidth - 14.0).toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _nextGuideStep,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black45),
          ),
        ),
        Positioned(
          left: targetRect.left + 2,
          top: targetRect.top + 2,
          child: IgnorePointer(
            child: Container(
              width: targetRect.width - 4,
              height: targetRect.height - 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: bubbleWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isBubbleAbove)
                    Padding(
                      padding: EdgeInsets.only(left: connectorX - 6),
                      child: const Icon(
                        Icons.arrow_drop_up,
                        color: Color(0xFF2A3158),
                        size: 16,
                      ),
                    ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A3158),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _guideSteps[_guideStepIndex].message,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: _nextGuideStep,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _guideStepIndex == _guideSteps.length - 1
                                      ? '完了'
                                      : '次へ',
                                  style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isBubbleAbove)
                    Padding(
                      padding: EdgeInsets.only(left: connectorX - 6),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF2A3158),
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextGuideStep() {
    _guideStepIndex++;
    _showGuideStep();
  }

  void _hideGuideOverlay() {
    _guideOverlay?.remove();
    _guideOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final challengeProgress = context.watch<ChallengeProgressNotifier>().progress;
    final gameState = _challengeService.createChallengeGameState(widget.level);

    return ChangeNotifierProvider(
      create: (_) => GameProvider(gameState),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'レベル ${widget.level.level}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1F3A),
          foregroundColor: Colors.white,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            if (_isSwipeNavigating) return;
            setState(() {
              _horizontalDragOffset = 0;
            });
          },
          onHorizontalDragUpdate: (details) {
            if (_isSwipeNavigating) return;
            setState(() {
              _horizontalDragOffset += details.primaryDelta ?? 0;
            });
          },
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          onHorizontalDragCancel: () {
            if (_isSwipeNavigating) return;
            setState(() {
              _horizontalDragOffset = 0;
            });
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildSwipePreview(challengeProgress),
              ),
              Transform.translate(
                offset: Offset(_horizontalDragOffset, 0),
                child: Container(
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
                  child: Consumer<GameProvider>(
                    builder: (context, provider, _) {
                      final state = provider.gameState;
                      final currentPlayer = state.getCurrentPlayer();

                      return SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // レベル情報
                                    _buildLevelInfo(context, state),
                                    
                                    // ボード
                                    ConstrainedBox(
                                      key: _boardAreaKey,
                                      constraints: BoxConstraints(
                                        maxHeight: constraints.maxHeight * 0.5,
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: BoardWidget(
                                            board: state.board,
                                            selectedPositions: _selectedPositions,
                                            highlightedPositions: _getAdjacentPositions(state.board),
                                            lastTwoBitGatePositions: const [],
                                            enableRowColumnButtons: true,
                                            selectedGate: _selectedGate,
                                            selectedRows: _selectedRow != null
                                                ? {_selectedRow!: true}
                                                : {},
                                            selectedColumns: _selectedColumn != null
                                                ? {_selectedColumn!: true}
                                                : {},
                                            onPositionTap: (position) {
                                              _handleCellTap(context, provider, position.row, position.col);
                                            },
                                            onRowSelected: (row, side) {
                                              _handleRowButtonTap(context, provider, row);
                                            },
                                            onColumnSelected: (col, side) {
                                              _handleColumnButtonTap(context, provider, col);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ゲート選択
                                    _buildGateSelection(context, provider, currentPlayer),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleHorizontalDragEnd(DragEndDetails details) async {
    if (_isSwipeNavigating) return;

    final dragDistance = _horizontalDragOffset;
    final swipeThreshold = MediaQuery.of(context).size.width * 0.25;

    if (dragDistance.abs() < swipeThreshold) {
      setState(() {
        _horizontalDragOffset = 0;
      });
      return;
    }

    setState(() {
      _isSwipeNavigating = true;
    });

    // 右方向スワイプ: 前のレベル、左方向スワイプ: 次のレベル
    final targetLevelNumber = dragDistance > 0
        ? widget.level.level - 1
        : widget.level.level + 1;

    final didNavigate = await _navigateToUnlockedLevel(targetLevelNumber);
    if (!didNavigate && mounted) {
      setState(() {
        _horizontalDragOffset = 0;
        _isSwipeNavigating = false;
      });
    }
  }

  Future<bool> _navigateToUnlockedLevel(int targetLevelNumber) async {
    if (targetLevelNumber < 1) return false;

    final allLevels = await _levelLoader.loadAllLevels();
    ChallengeLevel? targetLevel;
    for (final level in allLevels) {
      if (level.level == targetLevelNumber) {
        targetLevel = level;
        break;
      }
    }
    if (targetLevel == null) return false;
    if (!mounted) return false;

    final progressManager =
        context.read<ChallengeProgressNotifier>().progress;
    if (!progressManager.isLevelUnlocked(targetLevel.level)) return false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChallengeGameScreen(level: targetLevel!),
      ),
    );
    return true;
  }

  Widget _buildSwipePreview(ChallengeProgressManager progressManager) {
    if (_horizontalDragOffset == 0) return const SizedBox.shrink();

    final targetLevelNumber = _horizontalDragOffset > 0
        ? widget.level.level - 1
        : widget.level.level + 1;
    final level = _findLevelByNumber(targetLevelNumber);
    if (level == null) return const SizedBox.shrink();

    final isUnlocked = progressManager.isLevelUnlocked(level.level);
    final align = _horizontalDragOffset > 0
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final directionLabel = _horizontalDragOffset > 0 ? '<<' : '>>';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align,
      child: FractionallySizedBox(
        widthFactor: 0.45,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF11162D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                directionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              if (level.comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  level.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white70 : Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ChallengeLevel? _findLevelByNumber(int levelNumber) {
    for (final level in _allLevels) {
      if (level.level == levelNumber) return level;
    }
    return null;
  }

  Widget _buildLevelInfo(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.level.comment.isNotEmpty)
                  Text(
                    widget.level.comment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.level.comment.isNotEmpty) const SizedBox(height: 8),
                Container(
                  key: _goalConditionKey,
                  child: Text(
                    'ゴール: ${widget.level.victoryCondition.displayName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '最短ターン: ${widget.level.optimalTurns}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // ターンカウントを右上に表示
          Text(
            'ターン: ${state.turnCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateSelection(
    BuildContext context,
    GameProvider provider,
    Player? currentPlayer,
  ) {
    if (currentPlayer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '使用可能ゲート',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _hideGuideOverlay();
                  _showGateInfoDialog(context);
                },
                key: _gateInfoButtonKey,
                icon: const Icon(Icons.info_outline, color: Colors.white),
                tooltip: 'ゲート効果を見る',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGateButtons(widget.level.availableGates),
          const SizedBox(height: 16),
          if (_entangledErrorMessage != null)
            Text(
              _entangledErrorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          if (_entangledErrorMessage == null) ...[
            if (_selectedGate == null)
              const Text(
                'ゲートを選択してください',
                style: TextStyle(color: Colors.white70),
              ),
            if (_selectedGate != null && _selectedGate!.isTwoBitGate)
              Text(
                _selectedPositions.isEmpty
                    ? '1マス目を選択してください'
                    : _selectedPositions.length == 1
                        ? '2マス目を選択してください'
                        : '2マス選択済み',
                style: const TextStyle(color: Colors.white70),
              ),
            if (_selectedGate != null && _selectedGate!.isOneBitGate)
              const Text(
                '行/列ボタンまたはマスを選択してください',
                style: TextStyle(color: Colors.white70),
              ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            key: _applyGateButtonKey,
            onPressed: _canApplyGate()
                ? () => _applyGate(context, provider)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: _canApplyGate()
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'ゲートを適用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _resetLevel(context, provider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'リセット',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGateInfoDialog(BuildContext context) {
    const pages = [
      ('assets/GateCheckpng.png', 'ゲート効果①'),
      ('assets/blackCNOT_all.png', 'ゲート効果②'),
    ];

    int currentPage = 0;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1F3A),
              title: const Text(
                'ゲート効果',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.68,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: PageView.builder(
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setDialogState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Text(
                                pages[index].$2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    pages[index].$1,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentPage + 1} / ${pages.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGateButtons(List<GateType> availableGates) {
    // 使用可能なゲートをカテゴリごとに分類
    final oneBitGates = availableGates.where((g) => g.isOneBitGate).toList();
    final twoBitGates = availableGates.where((g) => g.isTwoBitGate).toList();
    
    // 1ビットゲートをH, X, Y, Zの順に並べる
    final orderedOneBitGates = [
      if (oneBitGates.contains(GateType.h)) GateType.h,
      if (oneBitGates.contains(GateType.x)) GateType.x,
      if (oneBitGates.contains(GateType.y)) GateType.y,
      if (oneBitGates.contains(GateType.z)) GateType.z,
    ];
    
    // 2ビットゲートをCNOT, SWAPの順に並べる
    final orderedTwoBitGates = [
      if (twoBitGates.contains(GateType.cnot)) GateType.cnot,
      if (twoBitGates.contains(GateType.swap)) GateType.swap,
    ];
    
    return Column(
      children: [
        // 1行目: 1ビットゲート
        if (orderedOneBitGates.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderedOneBitGates.map((gate) {
              final isSelected = _selectedGate == gate;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: SizedBox(
                  key: gate == GateType.x ? _xGateButtonKey : null,
                  width: 60,
                  child: GateButton(
                    gate: gate,
                    isEnabled: true,
                    isSelected: isSelected,
                    onTap: () {
                      _handleGateSelection(gate);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        if (orderedOneBitGates.isNotEmpty && orderedTwoBitGates.isNotEmpty)
          const SizedBox(height: 8),
        // 2行目: 2ビットゲート
        if (orderedTwoBitGates.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderedTwoBitGates.map((gate) {
              final isSelected = _selectedGate == gate;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: SizedBox(
                  width: 60,
                  child: GateButton(
                    gate: gate,
                    isEnabled: true,
                    isSelected: isSelected,
                    onTap: () {
                      _handleGateSelection(gate);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _handleGateSelection(GateType gate) {
    setState(() {
      _selectedGate = gate;
      _entangledErrorMessage = null;
      if (gate.isTwoBitGate) {
        // 元の挙動: 2ビットゲート選択時は選択状態を必ずクリア
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
      }
      // 1ビットゲートへ切り替え時、1/2マス選択だけをリセットする
      if (gate.isOneBitGate && _shouldResetSelectionForOneBitGate()) {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
      }
      // 4マス選択や行/列選択は維持
    });
  }

  bool _shouldResetSelectionForOneBitGate() {
    final isRowOrColumnSelection = _selectedRow != null || _selectedColumn != null;
    final isFourCellsSelection = _selectedPositions.length == 4;
    if (isRowOrColumnSelection || isFourCellsSelection) {
      return false;
    }
    return _selectedPositions.length == 1 || _selectedPositions.length == 2;
  }

  void _handleCellTap(
    BuildContext context,
    GameProvider provider,
    int row,
    int col,
  ) {
    setState(() {
      _entangledErrorMessage = null;
    });

    if (_selectedGate != null && _selectedGate!.isTwoBitGate) {
      // 2ビットゲート選択中: 2マス選択（エンタングル駒は選択不可、隣接した駒のみ選択可能）
      final position = Position(row, col);
      final piece = provider.gameState.board.getPiece(row, col);
      if (piece != null && piece.isEntangled) {
        // エンタングル駒は選択不可
        setState(() {
          _entangledErrorMessage = 'エンタングル駒は選択できません';
        });
        return;
      }
      
      // エラーメッセージをクリア
      setState(() {
        _entangledErrorMessage = null;
      });
      
      if (_selectedPositions.isEmpty) {
        // 1つ目の位置を選択
        setState(() {
          _selectedPositions = [position];
        });
      } else if (_selectedPositions.length == 1) {
        // 2つ目の位置を選択（隣接チェック）
        final firstPosition = _selectedPositions.first;
        if (position.isAdjacent(firstPosition)) {
          setState(() {
            _selectedPositions.add(position);
          });
        } else {
          // 隣接していない場合は、新しい位置を1つ目として設定
          setState(() {
            _selectedPositions = [position];
            _entangledErrorMessage = '隣接した駒のみ選択できます';
          });
        }
      } else if (_selectedPositions.length == 2) {
        // 既に2マス選択済みの場合、最初の選択をクリアして新しい選択に置き換え
        setState(() {
          _selectedPositions = [position];
        });
      }
      _selectedRow = null;
      _selectedColumn = null;
    } else {
      // 1ビットゲートまたはゲート未選択: 1マス選択で4マス自動選択（エンタングル駒が含まれる場合は選択不可）
      // 行/列選択が既にある場合はクリアして4マス選択に切り替え
      if (_selectedRow != null || _selectedColumn != null) {
        setState(() {
          _selectedRow = null;
          _selectedColumn = null;
        });
      }
      
      // 4マス選択を自動生成
      final position = Position(row, col);
      final fourPieces = _getFourPieces(position, provider.gameState.board);
      
      // エンタングル駒が含まれているかチェック
      bool hasEntangled = false;
      for (final pos in fourPieces) {
        final piece = provider.gameState.board.getPiece(pos.row, pos.col);
        if (piece != null && piece.isEntangled) {
          hasEntangled = true;
          break;
        }
      }
      
      // エンタングル駒が含まれていない場合のみ選択
      if (!hasEntangled) {
        setState(() {
          _selectedPositions = fourPieces;
          _entangledErrorMessage = null;
        });
      } else {
        setState(() {
          _entangledErrorMessage = 'エンタングル駒を含む領域は選択できません';
        });
      }
    }
  }
  
  /// 4マス選択を取得（2x2の正方形）
  List<Position> _getFourPieces(Position position, Board board) {
    final positions = <Position>[];
    final row = position.row;
    final col = position.col;
    
    // 仕様: そのマス、及び右に1マス、下に1マス、右下に1マスの正方4マスを選択
    // 右端/下端を選択した場合は自動補正し、そこを含む4マスの選択とする
    
    // 基準位置を決定（右端/下端の場合は左/上にシフト）
    int baseRow = row;
    int baseCol = col;
    
    // 右端の場合、左に1マスシフト
    if (col == board.cols - 1 && board.cols > 1) {
      baseCol = col - 1;
    }
    
    // 下端の場合、上に1マスシフト
    if (row == board.rows - 1 && board.rows > 1) {
      baseRow = row - 1;
    }
    
    // 4マスを選択: baseRow, baseCol とその右、下、右下
    final positionsToAdd = [
      Position(baseRow, baseCol),
      Position(baseRow, baseCol + 1),
      Position(baseRow + 1, baseCol),
      Position(baseRow + 1, baseCol + 1),
    ];
    
    for (final pos in positionsToAdd) {
      if (board.isValidPosition(pos.row, pos.col)) {
        positions.add(pos);
      }
    }
    
    return positions;
  }

  void _handleRowButtonTap(
    BuildContext context,
    GameProvider provider,
    int row,
  ) {
    // 2ビットゲート選択時は行選択不可
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;

    setState(() {
      _selectedRow = _selectedRow == row ? null : row;
      _selectedColumn = null;
      
      if (_selectedRow != null) {
        _selectedPositions = List.generate(8, (col) => Position(row, col));
      } else {
        _selectedPositions = [];
      }
      _entangledErrorMessage = null;
    });
  }

  void _handleColumnButtonTap(
    BuildContext context,
    GameProvider provider,
    int col,
  ) {
    // 2ビットゲート選択時は列選択不可
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;

    setState(() {
      _selectedColumn = _selectedColumn == col ? null : col;
      _selectedRow = null;
      
      if (_selectedColumn != null) {
        _selectedPositions = List.generate(8, (row) => Position(row, col));
      } else {
        _selectedPositions = [];
      }
      _entangledErrorMessage = null;
    });
  }

  bool _canApplyGate() {
    if (_selectedGate == null) return false;
    if (_selectedPositions.isEmpty) return false;

    if (_selectedGate!.isTwoBitGate) {
      return _selectedPositions.length == 2;
    } else {
      return _selectedPositions.length == 1 || 
             _selectedPositions.length == 8 ||
             _selectedPositions.length == 4;
    }
  }

  void _applyGate(BuildContext context, GameProvider provider) async {
    if (!_canApplyGate()) return;

    final success = await provider.applyGate(_selectedGate!, _selectedPositions);
    
    if (!success) {
      setState(() {
        _entangledErrorMessage = provider.errorMessage ?? 'ゲートを適用できませんでした';
      });
      return;
    }

    final newState = provider.gameState;

    // 勝利条件をチェック
    final isVictory = _challengeService.checkVictoryCondition(
      newState,
      widget.level.victoryCondition,
    );

    if (isVictory) {
      await _handleVictory(context, newState);
    } else {
      // チャレンジモードでは、ゲート選択は保持し、選択位置のみクリア
      setState(() {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _entangledErrorMessage = null;
      });
    }
  }

  void _resetLevel(BuildContext context, GameProvider provider) {
    // 初期状態を再作成
    final initialGameState = _challengeService.createChallengeGameState(widget.level);
    
    // GameProviderの状態をリセット
    provider.resetToState(initialGameState);
    
    // UIの選択状態もリセット
    setState(() {
      _selectedGate = null;
      _selectedPositions = [];
      _selectedRow = null;
      _selectedColumn = null;
      _entangledErrorMessage = null;
    });
  }

  Future<void> _handleVictory(BuildContext context, GameState state) async {
    final turnsUsed = state.turnCount;
    final stars = _calculateStars(turnsUsed, widget.level.optimalTurns);

    // 進捗を保存（サービス内で最新を再読込してからマージ）
    await context.read<ChallengeProgressNotifier>().completeLevel(
      widget.level.level,
      turnsUsed,
      widget.level.optimalTurns,
    );

    if (mounted) {
      final nextLevel = await _findNextLevelInStage();
      _showVictoryDialog(context, stars, turnsUsed, nextLevel);
    }
  }

  Future<ChallengeLevel?> _findNextLevelInStage() async {
    final allLevels = await _levelLoader.loadAllLevels();
    final nextLevelNumber = widget.level.level + 1;

    for (final level in allLevels) {
      if (level.level == nextLevelNumber &&
          level.stageNumber == widget.level.stageNumber) {
        return level;
      }
    }

    return null;
  }

  int _calculateStars(int turnsUsed, int optimalTurns) {
    if (turnsUsed <= optimalTurns) {
      return 3; // 最短ターンでクリア → 星3つ
    } else if (turnsUsed <= optimalTurns * 3) {
      return 2; // 最短ターンの3倍以内でクリア → 星2つ
    } else {
      return 1; // 3倍を超えたら → 星1つ
    }
  }

  void _showVictoryDialog(
    BuildContext context,
    int stars,
    int turnsUsed,
    ChallengeLevel? nextLevel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '🎉 レベルクリア！',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'レベル ${widget.level.level} をクリアしました！',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: index < stars ? Colors.amber : Colors.grey,
                  size: 32,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '使用ターン数: $turnsUsed',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop('ok');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (nextLevel != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop('next');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '次へ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).then((value) {
      if (!mounted) return;

      if (value == 'next' && nextLevel != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChallengeGameScreen(level: nextLevel),
          ),
        );
        return;
      }

      if (value == 'ok') {
        Navigator.of(context).pop(true);
      }
    });
  }

  /// 2ビットゲート選択時に、1つ目の位置に隣接する位置を取得
  List<Position> _getAdjacentPositions(Board board) {
    if (_selectedGate == null || !_selectedGate!.isTwoBitGate) {
      return [];
    }
    if (_selectedPositions.isEmpty) {
      return [];
    }

    final firstPosition = _selectedPositions.first;
    final adjacentPositions = <Position>[];

    // 隣接する8方向をチェック
    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue; // 自分自身は除外

        final newRow = firstPosition.row + rowOffset;
        final newCol = firstPosition.col + colOffset;

        if (board.isValidPosition(newRow, newCol)) {
          final adjacentPos = Position(newRow, newCol);
          // 既に選択されている位置は除外
          if (!_selectedPositions.contains(adjacentPos)) {
            adjacentPositions.add(adjacentPos);
          }
        }
      }
    }

    return adjacentPositions;
  }
}

