import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:q_reversi_app/domain/entities/board.dart';
import 'package:q_reversi_app/domain/entities/challenge_level.dart';
import 'package:q_reversi_app/domain/entities/gate_type.dart';
import 'package:q_reversi_app/domain/time_attack/time_attack_config.dart';
import 'package:q_reversi_app/domain/time_attack/time_attack_level_sequence_generator.dart';

ChallengeLevel _level({
  required int id,
  required int turns,
  required int difficulty,
}) {
  return ChallengeLevel(
    level: id,
    optimalTurns: turns,
    availableGates: const [GateType.x],
    victoryCondition: VictoryCondition.allWhite,
    initialBoard: Board.create8x8(),
    comment: '',
    difficulty: difficulty,
  );
}

void main() {
  test('score slots produce 50 unique levels with correct bands', () {
    final pool = <ChallengeLevel>[];
    // Fill each band with enough candidates
    var nextId = 1;
    void addBand(int minScore, int maxScore, int count) {
      for (var i = 0; i < count; i++) {
        final score = minScore + (i % (maxScore - minScore + 1));
        // score = turns + difficulty, use turns=1.. and difficulty = score-turns
        final turns = 1;
        final difficulty = score - turns;
        pool.add(_level(id: nextId++, turns: turns, difficulty: difficulty));
      }
    }

    for (final slot in TimeAttackConfig.scoreSlots) {
      addBand(slot.minScore, slot.maxScore, slot.count + 5);
    }

    final generator = TimeAttackLevelSequenceGenerator(random: Random(42));
    final sequence = generator.generate(pool);

    expect(sequence.length, TimeAttackConfig.totalLevels);
    expect(sequence.map((l) => l.level).toSet().length, sequence.length);

    var index = 0;
    for (final slot in TimeAttackConfig.scoreSlots) {
      final slice = sequence.sublist(index, index + slot.count);
      for (final level in slice) {
        expect(slot.matches(level.timeAttackScore), isTrue);
      }
      index += slot.count;
    }
  });

  test('Q1 is always score 2', () {
    final pool = <ChallengeLevel>[];
    var nextId = 1;
    for (final slot in TimeAttackConfig.scoreSlots) {
      for (var i = 0; i < slot.count + 3; i++) {
        final score = slot.minScore;
        pool.add(_level(id: nextId++, turns: 1, difficulty: score - 1));
      }
    }
    final sequence =
        TimeAttackLevelSequenceGenerator(random: Random(1)).generate(pool);
    expect(sequence.first.timeAttackScore, 2);
  });
}
