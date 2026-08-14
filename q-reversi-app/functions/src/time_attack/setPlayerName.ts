import { HttpsError, onCall } from "firebase-functions/v2/https";
import { timeAttackConfig } from "../config/timeAttackConfig";
import { setPlayerNameForUid } from "./playerNameService";

export const setPlayerName = onCall(
  {
    region: timeAttackConfig.region,
    maxInstances: 2,
    enforceAppCheck: true,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    try {
      const displayName = await setPlayerNameForUid(
        request.auth.uid,
        request.data?.name,
      );
      return { displayName };
    } catch (e) {
      const message = e instanceof Error ? e.message : "failed to set name";
      if (message === "name already taken") {
        throw new HttpsError("already-exists", message);
      }
      if (message === "name contains prohibited words") {
        throw new HttpsError(
          "invalid-argument",
          "使用できない言葉が含まれています",
        );
      }
      if (message.startsWith("name ")) {
        throw new HttpsError("invalid-argument", message);
      }
      throw new HttpsError("internal", message);
    }
  },
);
