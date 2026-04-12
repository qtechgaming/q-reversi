import 'package:flutter/material.dart';
import '../../data/vs_game_persistence_service.dart';
import '../../domain/entities/game_mode.dart';
import '../../core/constants/game_constants.dart';
import 'game_screen.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/player.dart';
import '../../domain/services/game_service.dart';
import '../../domain/services/vs_cpu_progress_service.dart';

/// VSモード設定画面
class VsModeSetupScreen extends StatefulWidget {
  const VsModeSetupScreen({super.key});

  @override
  State<VsModeSetupScreen> createState() => _VsModeSetupScreenState();
}

class _VsModeSetupScreenState extends State<VsModeSetupScreen> {
  static const Color _barLoss = Color(0xFFCF6679);
  static const Color _barDraw = Color(0xFFFFB74D);
  static const Color _barWin = Color(0xFF81C784);

  final VsCpuProgressService _vsCpuProgressService = VsCpuProgressService();
  final VsGamePersistenceService _vsPersistence = VsGamePersistenceService();

  VsMode _vsMode = VsMode.human;
  AIDifficulty _aiDifficulty = AIDifficulty.beginner;
  int _maxTurns = GameConstants.defaultVsModeTurns;
  VsCpuProgressSnapshot? _cpuProgress;
  bool _cpuProgressLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCpuProgress();
  }

  Future<void> _refreshCpuProgress() async {
    final snap = await _vsCpuProgressService.load();
    if (!mounted) return;
    setState(() {
      _cpuProgress = snap;
      _cpuProgressLoading = false;
      if (!snap.isUnlocked(_aiDifficulty)) {
        _aiDifficulty = AIDifficulty.beginner;
      }
    });
  }

  String _difficultyTitle(AIDifficulty d) {
    switch (d) {
      case AIDifficulty.beginner:
        return '初級';
      case AIDifficulty.intermediate:
        return '中級';
      case AIDifficulty.advanced:
        return '上級';
      case AIDifficulty.quantum:
        return '量子AI';
    }
  }

  Widget _buildDifficultyTitle(AIDifficulty d, bool unlocked) {
    if (d == AIDifficulty.quantum) {
      final labelRow = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '量子AI',
            style: TextStyle(
              color: unlocked ? const Color(0xFF9B6DFF) : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFF6B46C1) : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'QAZ Algorithm',
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white54,
                fontSize: 10,
              ),
            ),
          ),
        ],
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!unlocked) ...[
            Icon(Icons.lock_outline, size: 18, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.hardEdge,
              child: labelRow,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (!unlocked) ...[
          Icon(Icons.lock_outline, size: 18, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            _difficultyTitle(d),
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildOutcomeBar(VsCpuStats st) {
    if (st.played == 0) {
      return Container(
        height: 10,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: Row(
          children: [
            if (st.losses > 0)
              Expanded(
                flex: st.losses,
                child: Container(color: _barLoss),
              ),
            if (st.draws > 0)
              Expanded(
                flex: st.draws,
                child: Container(color: _barDraw),
              ),
            if (st.wins > 0)
              Expanded(
                flex: st.wins,
                child: Container(color: _barWin),
              ),
          ],
        ),
      ),
    );
  }

  /// 成績列の右半分の幅に棒グラフを表示
  Widget _buildOutcomeBarHalfWidth(VsCpuStats st) {
    return Row(
      children: [
        const Spacer(flex: 1),
        Expanded(
          flex: 1,
          child: _buildOutcomeBar(st),
        ),
      ],
    );
  }

  Widget _buildCpuStatsCell(VsCpuProgressSnapshot snap, AIDifficulty d) {
    if (!snap.isUnlocked(d)) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
      );
    }
    final st = snap.stats[d] ?? const VsCpuStats();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${st.wins}勝 / ${st.played}戦',
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _buildOutcomeBarHalfWidth(st),
      ],
    );
  }

  Widget _buildCpuDifficultyBlock() {
    if (_cpuProgressLoading || _cpuProgress == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
    }

    final snap = _cpuProgress!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CPU難易度',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '各難易度に勝利すると次の難易度が解放されます。',
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              flex: 5,
              child: Text(
                '難易度',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '成績',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _legendChip(_barLoss, '負'),
                      const SizedBox(width: 8),
                      _legendChip(_barDraw, '引'),
                      const SizedBox(width: 8),
                      _legendChip(_barWin, '勝'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...VsCpuProgressService.difficultiesOrder.map((d) {
          final unlocked = snap.isUnlocked(d);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: RadioListTile<AIDifficulty>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: _buildDifficultyTitle(d, unlocked),
                    subtitle: d == AIDifficulty.quantum
                        ? Text(
                            '量子コンピュータで機械学習したAI',
                            style: TextStyle(
                              color: unlocked ? Colors.white54 : Colors.white38,
                              fontSize: 11,
                            ),
                          )
                        : null,
                    value: d,
                    groupValue: _aiDifficulty,
                    onChanged: unlocked
                        ? (value) {
                            if (value != null) {
                              setState(() => _aiDifficulty = value);
                            }
                          }
                        : null,
                    activeColor:
                        d == AIDifficulty.quantum && unlocked ? const Color(0xFF9B6DFF) : null,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: _buildCpuStatsCell(snap, d),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VSモード設定',
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
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '対戦モード',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<VsMode>(
                title: const Text(
                  '対人戦',
                  style: TextStyle(color: Colors.white),
                ),
                value: VsMode.human,
                groupValue: _vsMode,
                onChanged: (value) {
                  setState(() => _vsMode = value!);
                },
              ),
              RadioListTile<VsMode>(
                title: const Text(
                  '対CPU戦',
                  style: TextStyle(color: Colors.white),
                ),
                value: VsMode.cpu,
                groupValue: _vsMode,
                onChanged: (value) {
                  setState(() => _vsMode = value!);
                },
              ),
              if (_vsMode == VsMode.cpu) ...[
                const SizedBox(height: 16),
                _buildCpuDifficultyBlock(),
              ],
              const SizedBox(height: 16),
              const Text(
                'ターン数',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...GameConstants.vsModeTurnOptions.map((turns) {
                return RadioListTile<int>(
                  title: Text(
                    '$turnsターン',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: turns,
                  groupValue: _maxTurns,
                  onChanged: (value) {
                    setState(() => _maxTurns = value!);
                  },
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _startGame(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'ゲーム開始',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(BuildContext context) async {
    await _vsPersistence.clear();
    if (!context.mounted) return;
    final board = Board.create8x8();

    const player1 = Player(
      id: 1,
      color: PlayerColor.white,
      isAI: false,
    );

    final player2 = Player(
      id: 2,
      color: PlayerColor.black,
      isAI: _vsMode == VsMode.cpu,
      aiDifficulty: _vsMode == VsMode.cpu ? _aiDifficulty : null,
    );

    final gameState = GameState(
      board: board,
      gameMode: GameMode.vs,
      vsMode: _vsMode,
      maxTurns: _maxTurns,
      currentPlayer: 1,
      players: {
        1: player1,
        2: player2,
      },
    );

    final gameService = GameService();
    final initializedState = gameService.createInitialBoard(gameState);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameState: initializedState),
      ),
    ).then((_) => _refreshCpuProgress());
  }
}
