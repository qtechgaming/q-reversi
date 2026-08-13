import catalogJson from "../generated/time_attack_level_catalog.json";
import {
  tierForQuestionIndex,
  timeAttackConfig,
  timeBonusMs,
} from "../config/timeAttackConfig";

export type CatalogLevel = {
  levelId: number;
  displayLabel: string;
  optimalTurns: number;
  difficulty: number;
  score: number;
};

export type SequenceLevel = CatalogLevel & {
  tier: number;
  timeBonusMs: number;
};

const catalog = catalogJson as CatalogLevel[];

const byId = new Map<number, CatalogLevel>(
  catalog.map((level) => [level.levelId, level]),
);

export function getCatalogLevel(levelId: number): CatalogLevel | undefined {
  return byId.get(levelId);
}

function shuffle<T>(items: T[]): T[] {
  const arr = [...items];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

export function generateSequence(): SequenceLevel[] {
  const used = new Set<number>();
  const sequence: SequenceLevel[] = [];

  for (const slot of timeAttackConfig.scoreSlots) {
    const candidates = catalog.filter(
      (level) =>
        !used.has(level.levelId) &&
        level.score >= slot.minScore &&
        level.score <= slot.maxScore,
    );
    if (candidates.length < slot.count) {
      throw new Error(
        `Score ${slot.minScore}-${slot.maxScore} candidates insufficient ` +
          `(need ${slot.count}, have ${candidates.length})`,
      );
    }
    const picked = shuffle(candidates).slice(0, slot.count);
    for (const level of picked) {
      used.add(level.levelId);
      const index = sequence.length;
      const tier = tierForQuestionIndex(index);
      sequence.push({
        ...level,
        tier,
        // Q1 は TIME ボーナスなし。以降は「次問への加算」用にこの問の optimal 基準で返す
        timeBonusMs:
          index === 0 ? 0 : timeBonusMs(level.optimalTurns, tier),
      });
    }
  }

  if (sequence.length !== timeAttackConfig.totalLevels) {
    throw new Error(`Invalid sequence length: ${sequence.length}`);
  }
  return sequence;
}
