import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/vs_game_persistence_service.dart';
import '../../domain/entities/game_mode.dart';
import '../../domain/services/tutorial_progress_service.dart';
import 'vs_mode_setup_screen.dart';
import 'game_screen.dart';
import 'challenge_flow_scope.dart';
import 'tutorial_screen.dart';
import 'study_mode_menu_screen.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/player.dart';
import '../../domain/services/game_service.dart';

/// ゲームモード選択画面
class GameModeSelectionScreen extends StatefulWidget {
  const GameModeSelectionScreen({super.key});

  @override
  State<GameModeSelectionScreen> createState() => _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> {
  final TutorialProgressService _progressService = TutorialProgressService();
  final VsGamePersistenceService _vsPersistence = VsGamePersistenceService();
  bool _isTutorialCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    // 管理者モード（デバッグビルド）ではチュートリアル制限をバイパス
    if (kDebugMode) {
      if (mounted) {
        setState(() {
          _isTutorialCompleted = true;
          _isLoading = false;
        });
      }
      return;
    }
    final isCompleted = await _progressService.isTutorialCompletedOrSkipped();
    if (mounted) {
      setState(() {
        _isTutorialCompleted = isCompleted;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Qリバーシ',
              style: TextStyle(color: Colors.white),
            ),
            if (kDebugMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
              _buildModeCard(
                context,
                'チュートリアル',
                'ゲームの遊び方説明',
                Icons.menu_book,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TutorialScreen(),
                    ),
                  );
                  // チュートリアル画面から戻ってきたら状態を再確認
                  _checkTutorialStatus();
                },
                enabled: true,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                'チャレンジモード',
                '特定の量子状態を作るパズルゲーム',
                Icons.flag,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengeFlowScope(),
                    ),
                  );
                },
                enabled: _isTutorialCompleted,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                'VSモード',
                '2人対戦のモード',
                Icons.people,
                () => _openVsMode(context),
                enabled: _isTutorialCompleted,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                'フリーランモード',
                '自由にゲートを演算できるモード',
                Icons.science,
                () {
                  _startFreeRunMode(context);
                },
                enabled: _isTutorialCompleted,
              ),
              const SizedBox(height: 16),
              _buildModeCard(
                context,
                'スタディモード',
                '量子コンピュータを感覚的に学習',
                Icons.school,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudyModeMenuScreen(),
                    ),
                  );
                },
                enabled: _isTutorialCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    required bool enabled,
    VoidCallback? onDisabledTap,
  }) {
    return Card(
      color: enabled
          ? const Color(0xFF1A1F3A).withOpacity(0.8)
          : const Color(0xFF1A1F3A).withOpacity(0.4),
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: enabled
              ? const Color(0xFF6B46C1)
              : Colors.grey.withOpacity(0.5),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: enabled
                ? Colors.white70
                : Colors.grey.withOpacity(0.5),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: enabled
              ? Colors.white70
              : Colors.grey.withOpacity(0.5),
        ),
        onTap: enabled
            ? onTap
            : () {
                if (onDisabledTap != null) {
                  onDisabledTap();
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'チュートリアルを完了またはスキップしてから、このモードをプレイできます',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
      ),
    );
  }
  
  Future<void> _openVsMode(BuildContext context) async {
    final hasSave = await _vsPersistence.hasSavedGame();
    if (!context.mounted) return;
    if (!hasSave) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VsModeSetupScreen(),
        ),
      );
      return;
    }
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '続きから対戦',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '前回の続きから対戦を開始しますか？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '最初から',
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
    );
    if (!context.mounted) return;
    if (resume == null) return;
    if (resume) {
      final snap = await _vsPersistence.loadSnapshot();
      if (!context.mounted) return;
      if (snap == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VsModeSetupScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameState: snap.gameState,
            initialPostGameMeasurementCompleted:
                snap.postGameMeasurementCompleted,
          ),
        ),
      );
    } else {
      await _vsPersistence.clear();
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VsModeSetupScreen(),
        ),
      );
    }
  }

  void _startFreeRunMode(BuildContext context) {
    final board = Board.create8x8();
    final gameState = GameState(
      board: board,
      gameMode: GameMode.freeRun,
      players: const {
        1: Player(
          id: 1,
          color: PlayerColor.black,
        ),
      },
    );
    
    final gameService = GameService();
    final initializedState = gameService.createInitialBoard(gameState);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameState: initializedState),
      ),
    );
  }
}

