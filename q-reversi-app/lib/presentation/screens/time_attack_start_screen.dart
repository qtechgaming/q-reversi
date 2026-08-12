import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/services/challenge_level_loader.dart';
import '../../domain/time_attack/time_attack_level_sequence_generator.dart';
import '../../domain/time_attack/time_attack_run_state.dart';
import '../widgets/operation_order_settings_dialog.dart';
import 'time_attack_game_screen.dart';
import 'time_attack_result_screen.dart';

class TimeAttackStartScreen extends StatefulWidget {
  const TimeAttackStartScreen({super.key});

  @override
  State<TimeAttackStartScreen> createState() => _TimeAttackStartScreenState();
}

class _TimeAttackStartScreenState extends State<TimeAttackStartScreen> {
  final _loader = ChallengeLevelLoader();
  bool _starting = false;
  String? _error;

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final levels = await _loader.loadAllLevels();
      final generator = TimeAttackLevelSequenceGenerator();
      final sequence = generator.generate(levels);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TimeAttackGameScreen(sequence: sequence),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  void _openResultPreview(TimeAttackRunState runState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimeAttackResultScreen(runState: runState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムアタックモード', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '操作設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showOperationOrderSettingsDialog(context),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'タイムアタック\nチャレンジ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '30秒からスタート。\n問題を解くとTIMEが追加されます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PERFECTを連続するとCOMBO BONUS!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB794F4), fontSize: 14),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _starting ? null : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _starting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'START',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ランキングは準備中です'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('RANKING（準備中）'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'DEBUG PREVIEW',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _openResultPreview(
                      TimeAttackRunState.previewTimeUp(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('TIME UP 画面を見る'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _openResultPreview(
                      TimeAttackRunState.previewAllClear(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ALL CLEAR 画面を見る'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
