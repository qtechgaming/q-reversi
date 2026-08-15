import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { timeAttackConfig } from "../config/timeAttackConfig";
import { maybeUpdateLeaderboard } from "./leaderboardService";
import { ensureDisplayName } from "./playerNameService";
import {
  ClientLevelResult,
  recalculateRun,
} from "./scoreCalculator";
import { SequenceLevel } from "./sequenceGenerator";

function asLevelResults(raw: unknown): ClientLevelResult[] {
  if (!Array.isArray(raw)) {
    throw new HttpsError("invalid-argument", "levelResults must be an array");
  }
  return raw.map((item, index) => {
    if (!item || typeof item !== "object") {
      throw new HttpsError("invalid-argument", `invalid levelResult at ${index}`);
    }
    const row = item as Record<string, unknown>;
    return {
      levelId: Number(row.levelId),
      cleared: Boolean(row.cleared),
      turnsUsed: Number(row.turnsUsed ?? 0),
      elapsedMs: Number(row.elapsedMs ?? 0),
      resetCount: Number(row.resetCount ?? 0),
    };
  });
}

export const submitTimeAttackRun = onCall(
  {
    region: timeAttackConfig.region,
    maxInstances: 2,
    enforceAppCheck: true,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    const uid = request.auth.uid;
    const runId = String(request.data?.runId ?? "");
    if (!runId) {
      throw new HttpsError("invalid-argument", "runId is required");
    }

    const levelResults = asLevelResults(request.data?.levelResults);
    const db = getFirestore();
    const runRef = db.collection("runs").doc(runId);
    const runSnap = await runRef.get();
    if (!runSnap.exists) {
      throw new HttpsError("not-found", "run not found");
    }
    const run = runSnap.data()!;
    if (run.uid !== uid) {
      throw new HttpsError("permission-denied", "run belongs to another user");
    }

    if (run.status === "completed" && run.officialResult) {
      // 前回: run 完了後に leaderboard 更新が落ちた場合の再送
      const official = run.officialResult as {
        clearCount: number;
        comboBonus: number;
        timeBonus: number;
        totalScore: number;
        maxCombo: number;
      };
      let displayName: string | undefined;
      try {
        displayName = await ensureDisplayName(uid);
        await maybeUpdateLeaderboard({
          uid,
          displayName,
          clearCount: Number(official.clearCount ?? 0),
          comboBonus: Number(official.comboBonus ?? 0),
          timeBonus: Number(official.timeBonus ?? 0),
          totalScore: Number(official.totalScore ?? 0),
          maxCombo: Number(official.maxCombo ?? 0),
          achievedAt: new Date().toISOString(),
          bestRunId: runId,
        });
      } catch {
        // 再送のランキング同期失敗は alreadyCompleted 応答を妨げない
      }
      return {
        runId,
        alreadyCompleted: true,
        officialResult: run.officialResult,
        displayName,
      };
    }

    const sequence = run.sequence as SequenceLevel[];
    if (!Array.isArray(sequence) || sequence.length === 0) {
      throw new HttpsError("failed-precondition", "run sequence missing");
    }

    let official;
    try {
      official = recalculateRun({ sequence, levelResults });
    } catch (e) {
      throw new HttpsError(
        "invalid-argument",
        e instanceof Error ? e.message : "failed to recalculate",
      );
    }

    const achievedAt = new Date().toISOString();
    await runRef.set(
      {
        status: "completed",
        finishReason: official.finishReason,
        clearCount: official.clearCount,
        comboBonus: official.comboBonus,
        timeBonus: official.timeBonus,
        clearBonus: official.clearBonus,
        totalScore: official.totalScore,
        perfectCount: official.perfectCount,
        maxCombo: official.maxCombo,
        remainingTimeMs: official.remainingTimeMs,
        levelResults: official.levelResults,
        officialResult: official,
        finishedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const displayName = await ensureDisplayName(uid);

    await maybeUpdateLeaderboard({
      uid,
      displayName,
      clearCount: official.clearCount,
      comboBonus: official.comboBonus,
      timeBonus: official.timeBonus,
      totalScore: official.totalScore,
      maxCombo: official.maxCombo,
      achievedAt,
      bestRunId: runId,
    });

    return {
      runId,
      alreadyCompleted: false,
      officialResult: official,
      displayName,
    };
  },
);
