import { HttpsError, onCall } from "firebase-functions/v2/https";
import { timeAttackConfig } from "../config/timeAttackConfig";
import { deleteUserData } from "../admin/userDataDeletion";

/** ログイン中ユーザー自身のランキング関連データを削除する */
export const deleteMyRankingData = onCall(
  {
    region: timeAttackConfig.region,
    maxInstances: 2,
    timeoutSeconds: 120,
    enforceAppCheck: true,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    try {
      const result = await deleteUserData(
        { uid: request.auth.uid },
        { deleteAuth: true },
      );
      return {
        ok: true,
        removedFromTimeAttackLeaderboard:
          result.removedFromTimeAttackLeaderboard,
        removedFromVsQuantumLeaderboard: result.removedFromVsQuantumLeaderboard,
        deletedRunCount: result.deletedRunCount,
      };
    } catch (e) {
      const message = e instanceof Error ? e.message : "failed to delete data";
      throw new HttpsError("internal", message);
    }
  },
);
