import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/board.dart';
import '../../domain/entities/challenge_level.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/position.dart';
import '../../domain/services/challenge_game_service.dart';
import '../../domain/services/operation_order_preference_service.dart';
import '../../domain/time_attack/time_attack_config.dart';
import '../../domain/time_attack/time_attack_run_state.dart';
import '../providers/game_provider.dart';
import '../providers/time_attack_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/gate_button.dart';
import 'time_attack_result_screen.dart';

class TimeAttackGameScreen extends StatefulWidget {
  final List<ChallengeLevel> sequence;
  final String? runId;

  const TimeAttackGameScreen({
    super.key,
    required this.sequence,
    this.runId,
  });

  @override
  State<TimeAttackGameScreen> createState() => _TimeAttackGameScreenState();
}

class _TimeAttackGameScreenState extends State<TimeAttackGameScreen>
    with WidgetsBindingObserver {
  final _challengeService = ChallengeGameService();
  final _operationOrderPrefs = OperationOrderPreferenceService();

  late final TimeAttackProvider _taProvider;
  late final GameProvider _gameProvider;

  GateType? _selectedGate;
  List<Position> _selectedPositions = [];
  int? _selectedRow;
  int? _selectedColumn;
  String? _errorMessage;
  bool _allowFreeSelectionOrder = false;
  bool _handlingClear = false;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taProvider = TimeAttackProvider(widget.sequence);
    _gameProvider = GameProvider(
      _challengeService.createChallengeGameState(
        widget.sequence.first,
        gameMode: GameMode.timeAttack,
      ),
    );
    _loadOperationOrderPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taProvider.startRun();
    });
    _taProvider.addListener(_onTaChanged);
  }

  Future<void> _loadOperationOrderPreference() async {
    final allowFree = await _operationOrderPrefs.isFreeSelectionOrderEnabled();
    if (!mounted) return;
    setState(() => _allowFreeSelectionOrder = allowFree);
  }

  void _onTaChanged() {
    if (!mounted) return;
    if (_taProvider.state.isFinished &&
        !_taProvider.state.isTransitioning &&
        !_navigatedToResult) {
      _goToResult();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _taProvider.refreshFromWallClock();
    }
  }

  @override
  void dispose() {
    _taProvider.removeListener(_onTaChanged);
    WidgetsBinding.instance.removeObserver(this);
    _taProvider.dispose();
    _gameProvider.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedGate = null;
      _selectedPositions = [];
      _selectedRow = null;
      _selectedColumn = null;
      _errorMessage = null;
    });
  }

  void _loadCurrentLevelBoard() {
    final level = _taProvider.state.currentLevel;
    _gameProvider.resetToState(
      _challengeService.createChallengeGameState(
        level,
        gameMode: GameMode.timeAttack,
      ),
    );
    _clearSelection();
  }

  Future<void> _goToResult() async {
    if (_navigatedToResult || !mounted) return;
    _navigatedToResult = true;
    final runState = _taProvider.state;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TimeAttackResultScreen(
          runState: runState,
          runId: widget.runId,
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    final totalTenths = (ms / 100).floor();
    final seconds = totalTenths ~/ 10;
    final tenths = totalTenths % 10;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins:${secs.toString().padLeft(2, '0')}.$tenths';
    }
    return '${secs.toString().padLeft(2, '0')}.$tenths';
  }

  Future<void> _onVictory() async {
    if (_handlingClear) return;
    _handlingClear = true;

    final turnsUsed = _gameProvider.gameState.turnCount;
    final flash = _taProvider.registerClear(turnsUsed: turnsUsed);
    if (flash == null) {
      _handlingClear = false;
      return;
    }

    if (!mounted) return;
    await _showClearOverlay(flash);

    if (!mounted) return;
    _taProvider.completeTransition();

    if (_taProvider.state.isFinished) {
      await _goToResult();
    } else {
      _loadCurrentLevelBoard();
    }
    _handlingClear = false;
  }

  Future<void> _showClearOverlay(TimeAttackClearFlash flash) async {
    final bonusSec = (flash.timeBonusMs / 1000).toStringAsFixed(1);
    final navigator = Navigator.of(context, rootNavigator: true);
    final dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, anim, secondary) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6B46C1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    flash.isAllClear
                        ? 'ALL CLEAR!'
                        : flash.isPerfect
                            ? 'PERFECT!'
                            : 'CLEAR!',
                    style: TextStyle(
                      color: flash.isPerfect || flash.isAllClear
                          ? const Color(0xFFFFD54F)
                          : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (flash.isPerfect && flash.comboStreak > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${flash.comboStreak} COMBO',
                      style: const TextStyle(
                        color: Color(0xFFB794F4),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (flash.comboBonusGained > 0)
                      Text(
                        '+${flash.comboBonusGained} BONUS',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                  if (!flash.isAllClear && flash.timeBonusMs > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'TIME +$bonusSec',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (!flash.isAllClear &&
                      flash.nextGoalLabel != null &&
                      flash.nextOptimalTurns != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFB794F4).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'NEXT',
                            style: TextStyle(
                              color: Color(0xFFB794F4),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ゴール: ${flash.nextGoalLabel}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '最短ターン: ${flash.nextOptimalTurns}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(TimeAttackConfig.clearOverlayDuration);
    if (navigator.canPop()) {
      navigator.pop();
    }
    await dialogFuture;
  }

  Future<void> _applyGate() async {
    final ta = _taProvider.state;
    if (!ta.canInteract || _handlingClear) return;
    if (!_canApplyGate()) return;

    final success =
        await _gameProvider.applyGate(_selectedGate!, _selectedPositions);
    if (!success) {
      setState(() {
        _errorMessage =
            _gameProvider.errorMessage ?? 'ゲートを適用できませんでした';
      });
      return;
    }

    final isVictory = _challengeService.checkVictoryCondition(
      _gameProvider.gameState,
      ta.currentLevel.victoryCondition,
    );

    if (isVictory) {
      await _onVictory();
    } else {
      setState(() {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _errorMessage = null;
      });
    }
  }

  void _resetLevel() {
    final ta = _taProvider.state;
    if (!ta.canInteract || _handlingClear) return;
    _taProvider.registerReset();
    _gameProvider.resetToState(
      _challengeService.createChallengeGameState(
        ta.currentLevel,
        gameMode: GameMode.timeAttack,
      ),
    );
    _clearSelection();
  }

  bool _canApplyGate() {
    if (_selectedGate == null) return false;
    if (_selectedPositions.isEmpty) return false;
    if (_selectedGate!.isTwoBitGate) {
      return _selectedPositions.length == 2;
    }
    return _selectedPositions.length == 1 ||
        _selectedPositions.length == 8 ||
        _selectedPositions.length == 4;
  }

  List<Position> _getFourPieces(Position position, Board board) {
    var baseRow = position.row;
    var baseCol = position.col;
    if (position.col == board.cols - 1 && board.cols > 1) {
      baseCol = position.col - 1;
    }
    if (position.row == board.rows - 1 && board.rows > 1) {
      baseRow = position.row - 1;
    }
    final positions = <Position>[];
    for (final pos in [
      Position(baseRow, baseCol),
      Position(baseRow, baseCol + 1),
      Position(baseRow + 1, baseCol),
      Position(baseRow + 1, baseCol + 1),
    ]) {
      if (board.isValidPosition(pos.row, pos.col)) {
        positions.add(pos);
      }
    }
    return positions;
  }

  List<Position> _getAdjacentPositions(Board board) {
    if (_selectedGate == null || !_selectedGate!.isTwoBitGate) {
      return const [];
    }
    if (_selectedPositions.isEmpty) return const [];
    final first = _selectedPositions.first;
    final adjacent = <Position>[];
    for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (var colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue;
        final newRow = first.row + rowOffset;
        final newCol = first.col + colOffset;
        if (!board.isValidPosition(newRow, newCol)) continue;
        final adjacentPos = Position(newRow, newCol);
        if (!_selectedPositions.contains(adjacentPos)) {
          adjacent.add(adjacentPos);
        }
      }
    }
    return adjacent;
  }

  void _handleCellTap(int row, int col) {
    if (!_taProvider.state.canInteract) return;
    if (!_allowFreeSelectionOrder && _selectedGate == null) {
      setState(() => _errorMessage = '先にゲートを選択してください');
      return;
    }

    setState(() => _errorMessage = null);
    final board = _gameProvider.gameState.board;

    if (_selectedGate != null && _selectedGate!.isTwoBitGate) {
      final position = Position(row, col);
      final piece = board.getPiece(row, col);
      if (piece != null && piece.isEntangled) {
        setState(() => _errorMessage = 'エンタングル駒は選択できません');
        return;
      }
      setState(() {
        if (_selectedPositions.isEmpty) {
          _selectedPositions = [position];
        } else if (_selectedPositions.length == 1) {
          if (position.isAdjacent(_selectedPositions.first)) {
            _selectedPositions = [..._selectedPositions, position];
          } else {
            _selectedPositions = [position];
            _errorMessage = '隣接した駒のみ選択できます';
          }
        } else {
          _selectedPositions = [position];
        }
        _selectedRow = null;
        _selectedColumn = null;
      });
      return;
    }

    setState(() {
      _selectedRow = null;
      _selectedColumn = null;
      final four = _getFourPieces(Position(row, col), board);
      var hasEntangled = false;
      for (final p in four) {
        final piece = board.getPiece(p.row, p.col);
        if (piece != null && piece.isEntangled) {
          hasEntangled = true;
          break;
        }
      }
      if (hasEntangled) {
        _errorMessage = 'エンタングル駒を含む範囲は選択できません';
        _selectedPositions = [];
      } else {
        _selectedPositions = four;
      }
    });
  }

  void _handleRowButtonTap(int row) {
    if (!_taProvider.state.canInteract) return;
    if (!_allowFreeSelectionOrder && _selectedGate == null) {
      setState(() => _errorMessage = '先にゲートを選択してください');
      return;
    }
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;
    setState(() {
      _selectedRow = _selectedRow == row ? null : row;
      _selectedColumn = null;
      _selectedPositions = _selectedRow != null
          ? List.generate(8, (col) => Position(row, col))
          : [];
      _errorMessage = null;
    });
  }

  void _handleColumnButtonTap(int col) {
    if (!_taProvider.state.canInteract) return;
    if (!_allowFreeSelectionOrder && _selectedGate == null) {
      setState(() => _errorMessage = '先にゲートを選択してください');
      return;
    }
    if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;
    setState(() {
      _selectedColumn = _selectedColumn == col ? null : col;
      _selectedRow = null;
      _selectedPositions = _selectedColumn != null
          ? List.generate(8, (row) => Position(row, col))
          : [];
      _errorMessage = null;
    });
  }

  void _selectGate(GateType gate) {
    if (!_taProvider.state.canInteract) return;
    setState(() {
      final changing = _selectedGate != gate;
      _selectedGate = gate;
      if (changing) {
        if (gate.isTwoBitGate ||
            (_selectedPositions.length != 4 &&
                _selectedPositions.length != 8)) {
          _selectedPositions = [];
          _selectedRow = null;
          _selectedColumn = null;
        }
      }
      _errorMessage = null;
    });
  }

  Color _timeColor(int remainingMs) {
    if (remainingMs < 5000) return Colors.redAccent;
    if (remainingMs < 10000) return Colors.orangeAccent;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TimeAttackProvider>.value(value: _taProvider),
        ChangeNotifierProvider<GameProvider>.value(value: _gameProvider),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _confirmExit(context);
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'タイムアタック',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1A1F3A),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmExit(context),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
              ),
            ),
            child: Consumer2<TimeAttackProvider, GameProvider>(
              builder: (context, ta, game, _) {
                final run = ta.state;
                final boardState = game.gameState;
                final level = run.currentLevel;

                return SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            children: [
                              _buildHud(run, boardState.turnCount, level.optimalTurns),
                              const SizedBox(height: 8),
                              Text(
                                'ゴール: ${level.victoryCondition.displayName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.48,
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AbsorbPointer(
                                      absorbing: !run.canInteract,
                                      child: BoardWidget(
                                        board: boardState.board,
                                        selectedPositions: _selectedPositions,
                                        highlightedPositions:
                                            _getAdjacentPositions(
                                          boardState.board,
                                        ),
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
                                          _handleCellTap(
                                            position.row,
                                            position.col,
                                          );
                                        },
                                        onRowSelected: (row, _) {
                                          _handleRowButtonTap(row);
                                        },
                                        onColumnSelected: (col, _) {
                                          _handleColumnButtonTap(col);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildGateButtons(level.availableGates),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: run.canInteract && _canApplyGate()
                                    ? _applyGate
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'ゲートを適用',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed:
                                    run.canInteract ? _resetLevel : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'リセット',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildHud(
    TimeAttackRunState run,
    int turnCount,
    int optimalTurns,
  ) {
    final timeColor = _timeColor(run.remainingMs);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _hudCell(
              'TIME',
              _formatTime(run.remainingMs),
              valueColor: timeColor,
            ),
          ),
          Expanded(
            child: _hudCell('CLEAR', '${run.clearCount}'),
          ),
          Expanded(
            child: _hudCell('最短ターン', '$optimalTurns'),
          ),
          Expanded(
            child: _hudCell('ターン', '$turnCount'),
          ),
          Expanded(
            child: _hudCell(
              'COMBO',
              '×${run.comboStreak}',
              valueColor: run.comboStreak > 0
                  ? const Color(0xFFB794F4)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudCell(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGateButtons(List<GateType> availableGates) {
    final oneBit = [
      if (availableGates.contains(GateType.h)) GateType.h,
      if (availableGates.contains(GateType.x)) GateType.x,
      if (availableGates.contains(GateType.y)) GateType.y,
      if (availableGates.contains(GateType.z)) GateType.z,
    ];
    final twoBit = [
      if (availableGates.contains(GateType.cnot)) GateType.cnot,
      if (availableGates.contains(GateType.swap)) GateType.swap,
    ];

    return Column(
      children: [
        if (oneBit.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: oneBit
                .map(
                  (gate) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SizedBox(
                      width: 60,
                      child: GateButton(
                        gate: gate,
                        isEnabled: true,
                        isSelected: _selectedGate == gate,
                        onTap: () => _selectGate(gate),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        if (oneBit.isNotEmpty && twoBit.isNotEmpty) const SizedBox(height: 8),
        if (twoBit.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: twoBit
                .map(
                  (gate) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SizedBox(
                      width: 60,
                      child: GateButton(
                        gate: gate,
                        isEnabled: true,
                        isSelected: _selectedGate == gate,
                        onTap: () => _selectGate(gate),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('終了しますか？', style: TextStyle(color: Colors.white)),
        content: const Text(
          '進行中のタイムアタックは破棄されます。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('終了'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}
