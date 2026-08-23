import { HttpsError, onCall } from "firebase-functions/v2/https";
import { timeAttackConfig } from "../config/timeAttackConfig";
import { ensureDisplayName } from "../time_attack/playerNameService";
import { maybeUpdateVsQuantumLeaderboard } from "./vsQuantumLeaderboardService";

export const syncVsQuantumWins = onCall(
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

    const rawWins = request.data?.wins;
    const winsNum = Number(rawWins);
    if (!Number.isFinite(winsNum) || winsNum < 0) {
      throw new HttpsError(
        "invalid-argument",
        "wins must be a non-negative integer",
      );
    }
    const wins = Math.floor(winsNum);

    try {
      const displayName = await ensureDisplayName(request.auth.uid);
      const result = await maybeUpdateVsQuantumLeaderboard({
        uid: request.auth.uid,
        displayName,
        wins,
      });
      return {
        updated: result.updated,
        wins: result.wins,
        displayName,
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "sync failed";
      if (message.includes("wins must")) {
        throw new HttpsError("invalid-argument", message);
      }
      throw new HttpsError("internal", message);
    }
  },
);
