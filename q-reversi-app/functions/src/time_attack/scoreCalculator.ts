import {
  clearBonusPoints,
  remainingTimeBonusPoints,
  timeAttackConfig,
} from "../config/timeAttackConfig";
import { getCatalogLevel, SequenceLevel } from "./sequenceGenerator";

export type ClientLevelResult = {
  levelId: number;
  cleared: boolean;
  turnsUsed: number;
  elapsedMs: number;
  resetCount: number;
};

export type OfficialResult = {
  finishReason: "timeUp" | "allClear";
  clearCount: number;
  perfectCount: number;
  maxCombo: number;
  comboBonus: number;
  timeBonus: number;
  clearBonus: number;
  totalScore: number;
  remainingTimeMs: number;
  levelResults: Array<
    ClientLevelResult & {
      isPerfect: boolean;
      optimalTurns: number;
    }
  >;
};

export function recalculateRun(params: {
  sequence: SequenceLevel[];
  levelResults: ClientLevelResult[];
}): OfficialResult {
  const { sequence } = params;
  let remaining = timeAttackConfig.initialTimeMs;
  let combo = 0;
  let comboBonus = 0;
  let clear = 0;
  let perfectCount = 0;
  let maxCombo = 0;
  const officialResults: OfficialResult["levelResults"] = [];

  for (let i = 0; i < params.levelResults.length; i++) {
    const client = params.levelResults[i];
    const expected = sequence[i];
    if (!expected || client.levelId !== expected.levelId) {
      throw new Error(`levelId mismatch at index ${i}`);
    }
    const catalog = getCatalogLevel(client.levelId);
    if (!catalog) {
      throw new Error(`unknown levelId ${client.levelId}`);
    }

    const elapsedMs = Math.max(0, Math.floor(client.elapsedMs));
    remaining -= elapsedMs;

    if (remaining <= 0) {
      remaining = 0;
      officialResults.push({
        levelId: client.levelId,
        cleared: false,
        turnsUsed: Math.max(0, Math.floor(client.turnsUsed)),
        elapsedMs,
        resetCount: Math.max(0, Math.floor(client.resetCount)),
        isPerfect: false,
        optimalTurns: catalog.optimalTurns,
      });
      break;
    }

    if (!client.cleared) {
      officialResults.push({
        levelId: client.levelId,
        cleared: false,
        turnsUsed: Math.max(0, Math.floor(client.turnsUsed)),
        elapsedMs,
        resetCount: Math.max(0, Math.floor(client.resetCount)),
        isPerfect: false,
        optimalTurns: catalog.optimalTurns,
      });
      break;
    }

    clear += 1;
    const turnsUsed = Math.max(0, Math.floor(client.turnsUsed));
    const resetCount = Math.max(0, Math.floor(client.resetCount));
    const isPerfect =
      turnsUsed === catalog.optimalTurns && resetCount === 0;
    if (isPerfect) {
      combo += 1;
      comboBonus += combo * timeAttackConfig.comboPointStep;
      perfectCount += 1;
      if (combo > maxCombo) maxCombo = combo;
    } else {
      combo = 0;
    }

    officialResults.push({
      levelId: client.levelId,
      cleared: true,
      turnsUsed,
      elapsedMs,
      resetCount,
      isPerfect,
      optimalTurns: catalog.optimalTurns,
    });

    if (clear >= timeAttackConfig.totalLevels) {
      break;
    }

    const next = sequence[i + 1];
    if (next) {
      remaining = Math.min(
        remaining + next.timeBonusMs,
        timeAttackConfig.maxTimeMs,
      );
    }
  }

  const allClear = clear >= timeAttackConfig.totalLevels;
  const timeBonus = allClear ? remainingTimeBonusPoints(remaining) : 0;
  const clearBonus = clearBonusPoints(clear);
  const totalScore = clearBonus + comboBonus + timeBonus;

  return {
    finishReason: allClear ? "allClear" : "timeUp",
    clearCount: clear,
    perfectCount,
    maxCombo,
    comboBonus,
    timeBonus,
    clearBonus,
    totalScore,
    remainingTimeMs: allClear ? remaining : 0,
    levelResults: officialResults,
  };
}
