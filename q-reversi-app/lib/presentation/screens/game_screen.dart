import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_navigator.dart';
import '../../data/vs_game_persistence_service.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/entities/piece_type.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/forbidden_area.dart';
import '../providers/game_provider.dart';
import '../../domain/services/vs_cpu_progress_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/gate_button.dart';
import '../widgets/piece_widget.dart';

/// ゲーム画面
class GameScreen extends StatefulWidget {
  final GameState gameState;
  /// 復元時: 測定済みフラグ（再測定防止）
  final bool initialPostGameMeasurementCompleted;

  const GameScreen({
    super.key,
    required this.gameState,
    this.initialPostGameMeasurementCompleted = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameProvider _gameProvider;

  GateType? _selectedGate;
  List<Position> _selectedPositions = [];
  int? _selectedRow;
  int? _selectedColumn;
  String? _selectedRowDirection; // 'left' or 'right'
  String? _selectedColumnDirection; // 'top' or 'bottom'
  int _lastObservedTurnCount = -1;
  String? _entangledErrorMessage; // エンタングル駒選択時のエラーメッセージ

  @override
  void initState() {
    super.initState();
    _gameProvider = GameProvider(
      widget.gameState,
      postGameMeasurementCompleted: widget.initialPostGameMeasurementCompleted,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _gameProvider.persistVsSnapshotIfNeeded();
    }
  }

  /// VSモードで戻る操作（測定済みはモード設定へ、その他は保存確認）
  Future<void> _handleVsPop(BuildContext context, GameProvider provider) async {
    if (!context.mounted) return;
    if (provider.gameState.gameMode != GameMode.vs) {
      Navigator.of(context).pop();
      return;
    }
    if (provider.postGameMeasurementCompleted) {
      await AppNavigator.exitVsToModeSetup();
      return;
    }
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '対戦の中断',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '続きから対戦できるように盤面を記録しておきますか？',
          style: TextStyle(color: Colors.white70),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '対戦に戻る',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'いいえ',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'はい',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == null) return;
    if (choice) {
      provider.persistVsSnapshotIfNeeded();
    } else {
      await VsGamePersistenceService().clear();
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameProvider>.value(
      value: _gameProvider,
      child: Consumer<GameProvider>(
        builder: (context, provider, _) {
          final state = provider.gameState;
          return PopScope(
            canPop: state.gameMode != GameMode.vs,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              await _handleVsPop(context, provider);
            },
            child: Scaffold(
        backgroundColor: const Color(0xFF1A1F3A), // 背景色を統一（一番下まで同じ色）
        appBar: AppBar(
          title: const Text(
            'Q-Reversi',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1F3A),
          foregroundColor: Colors.white,
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
          child: Builder(
            builder: (context) {
              final currentPlayer = state.getCurrentPlayer();
              
              // VSモード: CPU等が手を進めたタイミングで、ローカルな「2ビット選択UI」状態を残さない
              // `BoardWidget` 側は「2ビット選択中は禁止領域を表示しない」ため、ターン変化で必ずクリアする
              if (state.gameMode == GameMode.vs &&
                  state.turnCount != _lastObservedTurnCount) {
                final shouldClear = _selectedGate != null ||
                    _selectedPositions.isNotEmpty ||
                    _selectedRow != null ||
                    _selectedColumn != null;
                _lastObservedTurnCount = state.turnCount;
                if (shouldClear) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedGate = null;
                      _selectedPositions = [];
                      _selectedRow = null;
                      _selectedColumn = null;
                      _selectedRowDirection = null;
                      _selectedColumnDirection = null;
                      _entangledErrorMessage = null;
                    });
                  });
                }
              }
              
              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 全体をスクロール可能にする
                    final isVsMode = state.gameMode == GameMode.vs;
                    final isFreeRunMode = state.gameMode == GameMode.freeRun;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (isVsMode || isFreeRunMode)
                              ? 0 // VSモードとフリーランモードでは最小高さを0に設定
                              : constraints.maxHeight, // 最小高さを画面サイズに設定
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: (isVsMode || isFreeRunMode)
                              ? MainAxisAlignment.start 
                              : MainAxisAlignment.center,
                          children: [
                            // ゲーム情報
                            _buildGameInfo(context, state, currentPlayer),
                            
                            // ボード（画面サイズに応じて縮小可能）
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: (isVsMode || isFreeRunMode)
                                    ? constraints.maxHeight * 0.5 // VSモードとフリーランモードでは50%に設定
                                    : constraints.maxHeight * 0.6, // 画面の60%を最大値に
                                maxWidth: constraints.maxWidth,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: BoardWidget(
                                    board: state.board,
                                    selectedPositions: _selectedPositions,
                                    highlightedPositions: _getAdjacentPositions(state.board),
                                    lastTwoBitGatePositions: currentPlayer != null
                                        ? state.getLastTwoBitGatePositions(currentPlayer.id)
                                        : [],
                                    enableRowColumnButtons: state.gameMode == GameMode.freeRun || state.gameMode == GameMode.vs,
                                    selectedGate: _selectedGate,
                                    selectedRows: _selectedRow != null
                                        ? {_selectedRow!: true}
                                        : null,
                                    selectedColumns: _selectedColumn != null
                                        ? {_selectedColumn!: true}
                                        : null,
                                    forbiddenAreas: currentPlayer != null
                                        ? state.getForbiddenAreas(currentPlayer.id)
                                        : null,
                                    onPositionTap: (position) {
                                      _handlePositionTap(context, provider, position);
                                    },
                                    onRowSelected: (row, direction) {
                                      if (state.gameMode == GameMode.freeRun || state.gameMode == GameMode.vs) {
                                        _handleRowSelection(context, provider, row, direction);
                                      }
                                    },
                                    onColumnSelected: (col, direction) {
                                      if (state.gameMode == GameMode.freeRun || state.gameMode == GameMode.vs) {
                                        _handleColumnSelection(context, provider, col, direction);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            
                            // 下部エリア（固定サイズ）
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ゲート選択
                                if (currentPlayer?.isAI != true)
                                  _buildGateSelection(context, provider, currentPlayer),
                                
                                // 測定ボタン（ゲーム終了時・1回のみ）／測定後は閉じる
                                if (state.isGameOver &&
                                    !provider.postGameMeasurementCompleted)
                                  _buildMeasurementButton(context, provider),
                                if (state.isGameOver &&
                                    provider.postGameMeasurementCompleted)
                                  _buildPostGameBackButton(context),
                                
                                // エラーメッセージ
                                if (provider.errorMessage != null)
                                  _buildErrorMessage(context, provider),
                              ],
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
    );
        },
      ),
    );
  }
  
  Widget _buildGameInfo(
    BuildContext context,
    GameState state,
    Player? currentPlayer,
  ) {
    // 白と黒の駒のカウントを計算
    var whiteCount = 0;
    var blackCount = 0;
    for (int r = 0; r < state.board.rows; r++) {
      for (int c = 0; c < state.board.cols; c++) {
        final piece = state.board.getPiece(r, c);
        if (piece != null) {
          if (piece.type == PieceType.white) whiteCount++;
          if (piece.type == PieceType.black) blackCount++;
        }
      }
    }
    
    final isVsMode = state.gameMode == GameMode.vs;
    final isFreeRunMode = state.gameMode == GameMode.freeRun;
    
    // フリーランモードでは白と黒のカウントのみ右上に表示
    if (isFreeRunMode) {
      return Container(
        padding: const EdgeInsets.all(8), // VSモードと同じpaddingに設定
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '白: ',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '$whiteCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '黒: ',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '$blackCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(isVsMode ? 8 : 16), // VSモードではpaddingを減らす
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'ターン: ${state.turnCount}/${state.maxTurns}',
            style: const TextStyle(color: Colors.white),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'プレイヤー: ',
                style: TextStyle(color: Colors.white),
              ),
              // 盤面のセルと一緒に駒を表示
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEB887), // 盤面のセル背景色
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: PieceWidget(
                    piece: Piece(
                      id: 'player_icon',
                      type: currentPlayer?.color == PlayerColor.white
                          ? PieceType.white
                          : PieceType.black,
                      position: const Position(0, 0),
                    ),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '白: ',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '$whiteCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '黒: ',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '$blackCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (currentPlayer?.isAI == true)
            const Text(
              'CPU思考中...',
              style: TextStyle(color: Colors.cyan),
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
    
    final state = provider.gameState; // 最新の状態を取得
    final isVsMode = state.gameMode == GameMode.vs;
    
    // VSモードの場合、白プレイヤーと黒プレイヤーを取得
    Player? whitePlayer;
    Player? blackPlayer;
    if (isVsMode) {
      for (final player in state.players.values) {
        if (player.color == PlayerColor.white) {
          whitePlayer = player;
        } else if (player.color == PlayerColor.black) {
          blackPlayer = player;
        }
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // VSモードの場合は左右配置、それ以外は通常のWrap
          isVsMode && whitePlayer != null && blackPlayer != null
              ? Builder(
                  builder: (context) {
                    // nullチェック済みのローカル変数として再定義
                    final wp = whitePlayer!;
                    final bp = blackPlayer!;
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 白プレイヤーのゲート（左側）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'プレイヤー: 白',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 1行目：H, X
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.h, GateType.x].map((gate) {
                                  final cooldown = wp.cooldowns[gate] ?? 0;
                                  final isEnabled = wp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.white;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              // 2行目：Y, Z
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.y, GateType.z].map((gate) {
                                  final cooldown = wp.cooldowns[gate] ?? 0;
                                  final isEnabled = wp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.white;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              // 3行目：CNOT, SWAP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.cnot, GateType.swap].map((gate) {
                                  final cooldown = wp.cooldowns[gate] ?? 0;
                                  final isEnabled = wp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.white;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 黒プレイヤーのゲート（右側、中央寄せ）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'プレイヤー: 黒',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 1行目：H, X
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.h, GateType.x].map((gate) {
                                  final cooldown = bp.cooldowns[gate] ?? 0;
                                  final isEnabled = bp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.black;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              // 2行目：Y, Z
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.y, GateType.z].map((gate) {
                                  final cooldown = bp.cooldowns[gate] ?? 0;
                                  final isEnabled = bp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.black;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              // 3行目：CNOT, SWAP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [GateType.cnot, GateType.swap].map((gate) {
                                  final cooldown = bp.cooldowns[gate] ?? 0;
                                  final isEnabled = bp.canUseGate(gate);
                                  final isSelected = _selectedGate == gate;
                                  final isCurrentPlayer = currentPlayer.color == PlayerColor.black;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: SizedBox(
                                      width: 60,
                                      child: GateButton(
                                        gate: gate,
                                        isEnabled: isEnabled && isCurrentPlayer,
                                        isSelected: isSelected && isCurrentPlayer,
                                        cooldown: cooldown > 0 ? cooldown : null,
                                        onTap: isCurrentPlayer ? () {
                                          _handleGateSelection(gate);
                                        } : null,
                                        isReadOnly: !isCurrentPlayer,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                )
              : state.gameMode == GameMode.freeRun
                  ? Column(
                      children: [
                        // 1行目：H, X, Y, Z
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [GateType.h, GateType.x, GateType.y, GateType.z].map((gate) {
                            final cooldown = currentPlayer.cooldowns[gate] ?? 0;
                            final isEnabled = currentPlayer.canUseGate(gate);
                            final isSelected = _selectedGate == gate;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 60,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: isEnabled,
                                  isSelected: isSelected,
                                  cooldown: cooldown > 0 ? cooldown : null,
                                  onTap: () {
                                    _handleGateSelection(gate);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        // 2行目：CNOT, SWAP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [GateType.cnot, GateType.swap].map((gate) {
                            final cooldown = currentPlayer.cooldowns[gate] ?? 0;
                            final isEnabled = currentPlayer.canUseGate(gate);
                            final isSelected = _selectedGate == gate;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 60,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: isEnabled,
                                  isSelected: isSelected,
                                  cooldown: cooldown > 0 ? cooldown : null,
                                  onTap: () {
                                    _handleGateSelection(gate);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // 1行目：H, X
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [GateType.h, GateType.x].map((gate) {
                            final cooldown = currentPlayer.cooldowns[gate] ?? 0;
                            final isEnabled = currentPlayer.canUseGate(gate);
                            final isSelected = _selectedGate == gate;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 60,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: isEnabled,
                                  isSelected: isSelected,
                                  cooldown: cooldown > 0 ? cooldown : null,
                                  onTap: () {
                                    _handleGateSelection(gate);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        // 2行目：Y, Z
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [GateType.y, GateType.z].map((gate) {
                            final cooldown = currentPlayer.cooldowns[gate] ?? 0;
                            final isEnabled = currentPlayer.canUseGate(gate);
                            final isSelected = _selectedGate == gate;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 60,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: isEnabled,
                                  isSelected: isSelected,
                                  cooldown: cooldown > 0 ? cooldown : null,
                                  onTap: () {
                                    _handleGateSelection(gate);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        // 3行目：CNOT, SWAP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [GateType.cnot, GateType.swap].map((gate) {
                            final cooldown = currentPlayer.cooldowns[gate] ?? 0;
                            final isEnabled = currentPlayer.canUseGate(gate);
                            final isSelected = _selectedGate == gate;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                width: 60,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: isEnabled,
                                  isSelected: isSelected,
                                  cooldown: cooldown > 0 ? cooldown : null,
                                  onTap: () {
                                    _handleGateSelection(gate);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
          const SizedBox(height: 16),
          // エンタングル駒選択時のエラーメッセージ
          if (_entangledErrorMessage != null)
            Text(
              _entangledErrorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          if (_entangledErrorMessage == null) ...[
            if (_selectedGate != null && _selectedGate!.isTwoBitGate)
              Text(
                _selectedPositions.isEmpty
                    ? '1マス目を選択してください'
                    : _selectedPositions.length == 1
                        ? '2マス目を選択してください'
                        : '2マス選択済み',
                style: const TextStyle(color: Colors.white70),
              ),
            if (state.gameMode == GameMode.freeRun && 
                (_selectedGate == null || _selectedGate!.isOneBitGate))
              Text(
                _selectedGate == null
                    ? 'ゲートを選択してください'
                    : '行/列ボタンまたはマスを選択してください',
                style: const TextStyle(color: Colors.white70),
              ),
            if (state.gameMode == GameMode.vs && 
                (_selectedGate == null || _selectedGate!.isOneBitGate))
              Text(
                _selectedGate == null
                    ? 'ゲートを選択してください'
                    : '行/列ボタンまたはマスを選択してください',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
          const SizedBox(height: 16),
          // ゲートを適用ボタンと測定ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ゲートを適用ボタン（測定操作を実行ボタンが表示されていない場合のみ表示）
              if (!state.isGameOver)
                ElevatedButton(
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
              // VSモード用のゲート説明ボタン
              if (state.gameMode == GameMode.vs && !state.isGameOver) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showVsGateInfoDialog(context),
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'ゲート効果を見る',
                ),
              ],
              // 測定ボタン（フリーランモードのみ表示、VSモードでは非表示）
              if (state.gameMode == GameMode.freeRun && !state.isGameOver) ...[
                if (!state.isGameOver) const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _showMeasurementConfirmation(context, provider);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '測定',
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
          // リセットボタン群
          if (state.gameMode == GameMode.freeRun) ...[
            const SizedBox(height: 24),
            _buildResetButtons(context, provider),
          ],
        ],
      ),
    );
  }

  void _showVsGateInfoDialog(BuildContext context) {
    const pages = [
      ('assets/GateCheckpng.png', 'ゲート効果(CNOT以外)'),
      ('assets/blackCNOT_all.png', 'CNOT[プレイヤー白]'),
      ('assets/whiteCNOT_all.png', 'CNOT[プレイヤー黒]'),
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
  
  Widget _buildResetButtons(
    BuildContext context,
    GameProvider provider,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // 手を戻すボタン（フリーランモード専用）
        ElevatedButton(
          onPressed: provider.canUndo ? provider.undo : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: provider.canUndo
                ? Colors.grey.shade700
                : Colors.grey.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            '手を戻す',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        _buildResetButton(
          context,
          provider,
          'リセット',
          () => provider.reset(),
        ),
        _buildResetButton(
          context,
          provider,
          '盤面をすべて白にする',
          () => provider.setAllPiecesWhite(),
        ),
        _buildResetButton(
          context,
          provider,
          '盤面をすべて黒にする',
          () => provider.setAllPiecesBlack(),
        ),
      ],
    );
  }
  
  Widget _buildResetButton(
    BuildContext context,
    GameProvider provider,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.grey.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildMeasurementButton(
    BuildContext context,
    GameProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          _showMeasurementConfirmation(context, provider);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: const Color(0xFF6B46C1),
          foregroundColor: Colors.white,
        ),
        child: const Text(
          '測定操作を実行',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  /// 測定完了後：再測定・勝敗の二重加算を防ぐため、閉じるのみ
  Widget _buildPostGameBackButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => AppNavigator.exitVsToModeSetup(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          '閉じる',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
  
  void _showMeasurementConfirmation(
    BuildContext context,
    GameProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '測定の確認',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '測定し、結果を表示しますか？',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              provider.measure();
              await _showGameResult(context, provider);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showGameResult(BuildContext context, GameProvider provider) async {
    final state = provider.gameState;
    final board = state.board;
    var whiteCount = 0;
    var blackCount = 0;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final piece = board.getPiece(r, c);
        if (piece != null) {
          if (piece.type == PieceType.white) whiteCount++;
          if (piece.type == PieceType.black) blackCount++;
        }
      }
    }

    String result;
    if (whiteCount > blackCount) {
      result = '白の勝利！';
    } else if (blackCount > whiteCount) {
      result = '黒の勝利！';
    } else {
      result = '引き分け';
    }

    final vsCpu = state.gameMode == GameMode.vs &&
        state.vsMode == VsMode.cpu;
    final cpuDifficulty = state.players[2]?.aiDifficulty;
    if (vsCpu && cpuDifficulty != null) {
      final VsCpuGameOutcome outcome;
      if (whiteCount > blackCount) {
        outcome = VsCpuGameOutcome.win;
      } else if (blackCount > whiteCount) {
        outcome = VsCpuGameOutcome.loss;
      } else {
        outcome = VsCpuGameOutcome.draw;
      }
      await VsCpuProgressService().recordVsCpuGame(
        difficulty: cpuDifficulty,
        outcome: outcome,
      );
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'ゲーム終了',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$result\n白: $whiteCount, 黒: $blackCount',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorMessage(
    BuildContext context,
    GameProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => provider.clearError(),
          ),
        ],
      ),
    );
  }
  
  void _handleGateSelection(GateType gate) {
    setState(() {
      _selectedGate = gate;
      _entangledErrorMessage = null; // エラーメッセージをクリア
      if (gate.isTwoBitGate) {
        // 元の挙動: 2ビットゲート選択時は選択状態を必ずクリア
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _selectedRowDirection = null;
        _selectedColumnDirection = null;
      }
      // 1ビットゲートへ切り替え時、1/2マス選択だけをリセットする
      if (gate.isOneBitGate && _shouldResetSelectionForOneBitGate()) {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _selectedRowDirection = null;
        _selectedColumnDirection = null;
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
  
  void _handleRowSelection(
    BuildContext context,
    GameProvider provider,
    int row,
    String direction, // 'left' or 'right'
  ) {
    setState(() {
      // 2ビットゲート選択時は行選択不可
      if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;
      
      final isSameRow = _selectedRow == row;
      final isSameDirection = _selectedRowDirection == direction;
      final shouldDeselect = isSameRow && isSameDirection;

      _selectedRow = shouldDeselect ? null : row;
      _selectedRowDirection = shouldDeselect ? null : direction;
      _selectedColumn = null;
      _selectedColumnDirection = null;
      
      if (_selectedRow != null) {
        // エンタングル駒の手前まで選択範囲を制限
        _selectedPositions = _getRowPositionsUntilEntangled(
          provider.gameState.board,
          row,
          direction,
        );
      } else {
        _selectedPositions = [];
      }
    });
  }
  
  void _handleColumnSelection(
    BuildContext context,
    GameProvider provider,
    int col,
    String direction, // 'top' or 'bottom'
  ) {
    setState(() {
      // 2ビットゲート選択時は列選択不可
      if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;
      
      final isSameColumn = _selectedColumn == col;
      final isSameDirection = _selectedColumnDirection == direction;
      final shouldDeselect = isSameColumn && isSameDirection;

      _selectedColumn = shouldDeselect ? null : col;
      _selectedColumnDirection = shouldDeselect ? null : direction;
      _selectedRow = null;
      _selectedRowDirection = null;
      
      if (_selectedColumn != null) {
        // エンタングル駒の手前まで選択範囲を制限
        _selectedPositions = _getColumnPositionsUntilEntangled(
          provider.gameState.board,
          col,
          direction,
        );
      } else {
        _selectedPositions = [];
      }
    });
  }
  
  void _handlePositionTap(
    BuildContext context,
    GameProvider provider,
    Position position,
  ) {
    setState(() {
      if (_selectedGate != null && _selectedGate!.isTwoBitGate) {
        // 2ビットゲート選択中: 2マス選択（エンタングル駒は選択不可、隣接した駒のみ選択可能）
        final piece = provider.gameState.board.getPiece(position.row, position.col);
        if (piece != null && piece.isEntangled) {
          // エンタングル駒は選択不可
          _entangledErrorMessage = 'エンタングル駒は選択できません';
          return;
        }
        
        // エラーメッセージをクリア
        _entangledErrorMessage = null;
        
        if (_selectedPositions.isEmpty) {
          // 1つ目の位置を選択
          _selectedPositions = [position];
        } else if (_selectedPositions.length == 1) {
          // 2つ目の位置を選択（隣接チェック）
          final firstPosition = _selectedPositions.first;
          if (position.isAdjacent(firstPosition)) {
            _selectedPositions.add(position);
          } else {
            // 隣接していない場合は、新しい位置を1つ目として設定
            _selectedPositions = [position];
            _entangledErrorMessage = '隣接した駒のみ選択できます';
            return;
          }
        } else if (_selectedPositions.length == 2) {
          // 既に2マス選択済みの場合、最初の選択をクリアして新しい選択に置き換え
          _selectedPositions = [position];
        }
        _selectedRow = null;
        _selectedColumn = null;
        _selectedRowDirection = null;
        _selectedColumnDirection = null;
      } else {
        // 1ビットゲートまたはゲート未選択: 1マス選択で4マス自動選択（エンタングル駒が含まれる場合は選択不可）
        _selectedRow = null;
        _selectedColumn = null;
        _selectedRowDirection = null;
        _selectedColumnDirection = null;
        
        // 禁止領域チェック: 4マス選択の場合、禁止領域の4マスを始点とする4マス選択を禁止
        final currentPlayer = provider.gameState.getCurrentPlayer();
        if (currentPlayer != null) {
          final forbiddenAreas = provider.gameState.getForbiddenAreas(currentPlayer.id);
          for (final area in forbiddenAreas) {
            if (area.type == ForbiddenAreaType.fourPieces && area.positions != null) {
              // 禁止領域の4マスのいずれかが始点となる4マス選択を禁止
              for (final forbiddenPos in area.positions!) {
                if (forbiddenPos == position) {
                  _entangledErrorMessage = 'この位置は禁止領域です。相手が前回使用した領域には置けません。';
                  return;
                }
              }
            }
          }
        }
        
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
          _selectedPositions = fourPieces;
          _entangledErrorMessage = null; // エラーメッセージをクリア
        } else {
          _entangledErrorMessage = 'エンタングル駒を含む領域は選択できません';
        }
      }
    });
  }
  
  bool _canApplyGate() {
    if (_selectedGate == null || _selectedPositions.isEmpty) return false;
    
    if (_selectedGate!.isTwoBitGate) {
      // 2ビットゲート: 2マス選択が必要
      return _selectedPositions.length == 2;
    } else {
      // 1ビットゲート: 1マス以上選択されていればOK
      return _selectedPositions.isNotEmpty;
    }
  }
  
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
  
  /// 行選択でエンタングル駒の手前まで選択範囲を取得
  List<Position> _getRowPositionsUntilEntangled(
    Board board,
    int row,
    String direction, // 'left' or 'right'
  ) {
    final positions = <Position>[];
    
    if (direction == 'left') {
      // 左から（col=0から）エンタングル駒の手前まで
      for (int col = 0; col < board.cols; col++) {
        final piece = board.getPiece(row, col);
        if (piece != null && piece.isEntangled) {
          break; // エンタングル駒に到達したら終了
        }
        positions.add(Position(row, col));
      }
    } else {
      // 右から（col=cols-1から）エンタングル駒の手前まで
      for (int col = board.cols - 1; col >= 0; col--) {
        final piece = board.getPiece(row, col);
        if (piece != null && piece.isEntangled) {
          break; // エンタングル駒に到達したら終了
        }
        positions.add(Position(row, col));
      }
    }
    
    return positions;
  }
  
  /// 列選択でエンタングル駒の手前まで選択範囲を取得
  List<Position> _getColumnPositionsUntilEntangled(
    Board board,
    int col,
    String direction, // 'top' or 'bottom'
  ) {
    final positions = <Position>[];
    
    if (direction == 'top') {
      // 上から（row=0から）エンタングル駒の手前まで
      for (int row = 0; row < board.rows; row++) {
        final piece = board.getPiece(row, col);
        if (piece != null && piece.isEntangled) {
          break; // エンタングル駒に到達したら終了
        }
        positions.add(Position(row, col));
      }
    } else {
      // 下から（row=rows-1から）エンタングル駒の手前まで
      for (int row = board.rows - 1; row >= 0; row--) {
        final piece = board.getPiece(row, col);
        if (piece != null && piece.isEntangled) {
          break; // エンタングル駒に到達したら終了
        }
        positions.add(Position(row, col));
      }
    }
    
    return positions;
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
  
  Future<void> _applyGate(
    BuildContext context,
    GameProvider provider,
  ) async {
    if (_selectedGate == null) return;
    
    // 行/列選択の場合、禁止領域設定のために行/列全体の位置を使用
    List<Position> targetPositions;
    if (_selectedRow != null) {
      // 行選択の場合、その行全体を“選択ボタン側からの順序”で渡す
      // gate_service の entangled break は targetPositions の順序に依存するため、ハイライトと一致させる
      final cols = provider.gameState.board.cols;
      final isFromRight = _selectedRowDirection == 'right';
      targetPositions = List.generate(
        cols,
        (i) {
          final col = isFromRight ? (cols - 1 - i) : i;
          return Position(_selectedRow!, col);
        },
      );
    } else if (_selectedColumn != null) {
      // 列選択の場合、その列全体を“選択ボタン側からの順序”で渡す
      final rows = provider.gameState.board.rows;
      final isFromBottom = _selectedColumnDirection == 'bottom';
      targetPositions = List.generate(
        rows,
        (i) {
          final row = isFromBottom ? (rows - 1 - i) : i;
          return Position(row, _selectedColumn!);
        },
      );
    } else {
      // 4マス選択または2ビットゲート選択の場合、選択された位置を使用
      if (_selectedPositions.isEmpty) return;
      targetPositions = _selectedPositions;
    }
    
    final success = await provider.applyGate(
      _selectedGate!,
      targetPositions,
    );
    
    if (success) {
      setState(() {
        _selectedGate = null;
        _selectedPositions = [];
        _selectedRow = null;
        _selectedColumn = null;
        _selectedRowDirection = null;
        _selectedColumnDirection = null;
      });
    }
  }
}

