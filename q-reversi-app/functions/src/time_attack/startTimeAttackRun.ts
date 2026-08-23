import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { timeAttackConfig } from "../config/timeAttackConfig";
import { generateSequence } from "./sequenceGenerator";

export const startTimeAttackRun = onCall(
  {
    region: timeAttackConfig.region,
    maxInstances: 2,
    enforceAppCheck: true,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    if (request.data?.warmup === true) {
      return { warmed: true };
    }
    const uid = request.auth.uid;

    let sequence;
    try {
      sequence = generateSequence();
    } catch (e) {
      throw new HttpsError(
        "failed-precondition",
        e instanceof Error ? e.message : "Failed to generate sequence",
      );
    }

    const db = getFirestore();
    const runRef = db.collection("runs").doc();
    const levelIds = sequence.map((l) => l.levelId);

    await runRef.set({
      uid,
      status: "active",
      configVersion: timeAttackConfig.configVersion,
      levelIds,
      sequence,
      startedAt: FieldValue.serverTimestamp(),
    });

    return {
      runId: runRef.id,
      configVersion: timeAttackConfig.configVersion,
      initialTimeMs: timeAttackConfig.initialTimeMs,
      maxTimeMs: timeAttackConfig.maxTimeMs,
      comboPointStep: timeAttackConfig.comboPointStep,
      clearBonusPerClear: timeAttackConfig.clearBonusPerClear,
      timeBonusUnitMs: timeAttackConfig.timeBonusUnitMs,
      timeBonusPointsPerUnit: timeAttackConfig.timeBonusPointsPerUnit,
      levels: sequence.map((l) => ({
        levelId: l.levelId,
        tier: l.tier,
        timeBonusMs: l.timeBonusMs,
        optimalTurns: l.optimalTurns,
        score: l.score,
        difficulty: l.difficulty,
      })),
    };
  },
);
