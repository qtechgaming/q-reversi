import { FieldValue, getFirestore } from "firebase-admin/firestore";

export type VsQuantumRankingEntry = {
  uid: string;
  name: string;
  wins: number;
  achievedAt: string;
};

export const VS_QUANTUM_LEADERBOARD_DOC = "leaderboards/vs_quantum";
const MAX_ENTRIES = 1000;

function compareEntries(
  a: VsQuantumRankingEntry,
  b: VsQuantumRankingEntry,
): number {
  if (b.wins !== a.wins) return b.wins - a.wins;
  return a.achievedAt.localeCompare(b.achievedAt);
}

/** wins が増えたときだけ users + leaderboard を更新 */
export async function maybeUpdateVsQuantumLeaderboard(params: {
  uid: string;
  displayName: string;
  wins: number;
}): Promise<{ updated: boolean; wins: number }> {
  const wins = Math.floor(params.wins);
  if (!Number.isFinite(wins) || wins < 0) {
    throw new Error("wins must be a non-negative integer");
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(params.uid);
  const boardRef = db.doc(VS_QUANTUM_LEADERBOARD_DOC);
  const achievedAt = new Date().toISOString();

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data() ?? {};
    const prevWins = (user.vsQuantumWins as number | undefined) ?? 0;
    if (wins <= prevWins) {
      return { updated: false, wins: prevWins };
    }

    const displayName =
      (typeof user.displayName === "string" && user.displayName.trim()) ||
      params.displayName.trim();

    tx.set(
      userRef,
      {
        displayName: displayName || user.displayName || null,
        vsQuantumWins: wins,
        vsQuantumAchievedAt: achievedAt,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: user.createdAt ?? FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (!displayName) {
      return { updated: true, wins };
    }

    const boardSnap = await tx.get(boardRef);
    const entries = (
      (boardSnap.data()?.entries as VsQuantumRankingEntry[] | undefined) ?? []
    ).filter((e) => e.uid !== params.uid);

    entries.push({
      uid: params.uid,
      name: displayName,
      wins,
      achievedAt,
    });
    entries.sort(compareEntries);
    const trimmed = entries.slice(0, MAX_ENTRIES);

    tx.set(
      boardRef,
      {
        version: 1,
        updatedAt: FieldValue.serverTimestamp(),
        entries: trimmed,
      },
      { merge: true },
    );

    return { updated: true, wins };
  });
}
