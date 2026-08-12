import 'package:flutter/material.dart';

import '../../domain/time_attack/time_attack_run_state.dart';

class TimeAttackResultScreen extends StatelessWidget {
  final TimeAttackRunState runState;

  const TimeAttackResultScreen({
    super.key,
    required this.runState,
  });

  bool get _isTimeUp => runState.endReason == TimeAttackEndReason.timeUp;
  bool get _isAllClear => runState.endReason == TimeAttackEndReason.allClear;

  @override
  Widget build(BuildContext context) {
    final remainingSec = (runState.remainingMs / 1000).toStringAsFixed(1);

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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroHeader(),
                const SizedBox(height: 28),
                _buildClearHero(),
                const SizedBox(height: 20),
                _buildStatsCard(
                  remainingSec: remainingSec,
                ),
                const Spacer(),
                _buildTotalScore(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'モード選択へ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    if (_isTimeUp) {
      return const Text(
        'TIME UP!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF80DEEA),
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isAllClear) {
      return const Text(
        'ALL CLEAR!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return const Text(
      'RESULT',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildClearHero() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text(
            'CLEAR',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${runState.clearCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({required String remainingSec}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _statRow('CLEAR BONUS', '+${runState.clearBonusPoints}'),
          _statRow('MAX COMBO', '×${runState.maxCombo}'),
          _statRow('COMBO BONUS', '+${runState.comboBonus}'),
          if (_isAllClear) ...[
            _statRow('残りTIME', '${remainingSec}s'),
            _statRow('TIME BONUS', '+${runState.timeBonusPoints}'),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalScore() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B46C1).withValues(alpha: 0.35),
            const Color(0xFF6B46C1).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFB794F4).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL SCORE',
            style: TextStyle(
              color: Color(0xFFB794F4),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${runState.totalScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 15)),
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
}
