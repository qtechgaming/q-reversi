export const timeAttackConfig = {
  configVersion: 1,
  totalLevels: 50,
  initialTimeMs: 30_000,
  maxTimeMs: 60_000,
  comboPointStep: 10,
  clearBonusPerClear: 1000,
  timeBonusUnitMs: 100,
  timeBonusPointsPerUnit: 10,
  region: "asia-northeast1",
  tierMultipliers: {
    1: 3.0,
    2: 2.5,
    3: 2.0,
    4: 1.5,
    5: 1.0,
  } as Record<number, number>,
  scoreSlots: [
    { count: 1, minScore: 2, maxScore: 2 },
    { count: 4, minScore: 3, maxScore: 5 },
    { count: 5, minScore: 6, maxScore: 6 },
    { count: 10, minScore: 7, maxScore: 8 },
    { count: 10, minScore: 9, maxScore: 10 },
    { count: 10, minScore: 11, maxScore: 12 },
    { count: 6, minScore: 13, maxScore: 14 },
    { count: 4, minScore: 15, maxScore: 999 },
  ],
};

export function tierForQuestionIndex(index: number): number {
  if (index < 0) return 1;
  if (index >= timeAttackConfig.totalLevels) return 5;
  return Math.floor(index / 10) + 1;
}

export function timeBonusMs(optimalTurns: number, tier: number): number {
  const multiplier =
    timeAttackConfig.tierMultipliers[tier] ??
    timeAttackConfig.tierMultipliers[5];
  return Math.round(optimalTurns * multiplier * 1000);
}

export function clearBonusPoints(clearCount: number): number {
  if (clearCount <= 0) return 0;
  return clearCount * timeAttackConfig.clearBonusPerClear;
}

export function remainingTimeBonusPoints(remainingMs: number): number {
  if (remainingMs <= 0) return 0;
  return (
    Math.floor(remainingMs / timeAttackConfig.timeBonusUnitMs) *
    timeAttackConfig.timeBonusPointsPerUnit
  );
}
