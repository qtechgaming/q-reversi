import 'dart:math';

import '../entities/challenge_level.dart';
import 'time_attack_config.dart';
import 'time_attack_score_resolver.dart';

class TimeAttackSequenceException implements Exception {
  final String message;
  TimeAttackSequenceException(this.message);

  @override
  String toString() => message;
}

/// 仕様 #7 / #8 に従い 50問 sequence を生成する
class TimeAttackLevelSequenceGenerator {
  final TimeAttackScoreResolver _scoreResolver;
  final Random _random;

  TimeAttackLevelSequenceGenerator({
    TimeAttackScoreResolver? scoreResolver,
    Random? random,
  })  : _scoreResolver = scoreResolver ?? const TimeAttackScoreResolver(),
        _random = random ?? Random();

  /// TIME ATTACK 対象プール（0-1〜0-15 と 1〜300）
  static List<ChallengeLevel> filterPool(List<ChallengeLevel> all) {
    return all.where((level) {
      if (ChallengeLevel.isStage0Level(level.level)) return true;
      return level.level >= 1 && level.level <= 300;
    }).toList();
  }

  /// 各 score 帯に必要数が揃っているか
  static bool canStart(List<ChallengeLevel> pool) {
    try {
      validatePool(pool);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void validatePool(List<ChallengeLevel> pool) {
    final filtered = filterPool(pool);
    for (final slot in TimeAttackConfig.scoreSlots) {
      final count = filtered
          .where((l) => slot.matches(l.timeAttackScore))
          .length;
      if (count < slot.count) {
        throw TimeAttackSequenceException(
          'Score ${slot.minScore}-${slot.maxScore} の候補が不足しています'
          '（必要 ${slot.count} / 実際 $count）',
        );
      }
    }
  }

  List<ChallengeLevel> generate(List<ChallengeLevel> allLevels) {
    final pool = filterPool(allLevels);
    validatePool(pool);

    final usedIds = <int>{};
    final sequence = <ChallengeLevel>[];

    for (final slot in TimeAttackConfig.scoreSlots) {
      final candidates = pool
          .where(
            (l) =>
                !usedIds.contains(l.level) &&
                slot.matches(_scoreResolver.scoreForLevel(l)),
          )
          .toList();
      candidates.shuffle(_random);

      if (candidates.length < slot.count) {
        throw TimeAttackSequenceException(
          'Score ${slot.minScore}-${slot.maxScore} の抽選に失敗しました'
          '（必要 ${slot.count} / 候補 ${candidates.length}）',
        );
      }

      final picked = candidates.take(slot.count).toList()..shuffle(_random);
      for (final level in picked) {
        usedIds.add(level.level);
        sequence.add(level);
      }
    }

    if (sequence.length != TimeAttackConfig.totalLevels) {
      throw TimeAttackSequenceException(
        'sequence 長が不正です: ${sequence.length}',
      );
    }

    final uniqueIds = sequence.map((l) => l.level).toSet();
    if (uniqueIds.length != sequence.length) {
      throw TimeAttackSequenceException('levelId が重複しています');
    }

    return sequence;
  }
}
