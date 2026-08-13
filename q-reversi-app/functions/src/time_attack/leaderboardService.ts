import { FieldValue, getFirestore } from "firebase-admin/firestore";

type RankingEntry = {
  uid: string;
  name: string;
  clearCount: number;
  comboBonus: number;
  timeBonus: number;
  totalScore: number;
  maxCombo: number;
  achievedAt: string;
};

const LEADERBOARD_DOC = "leaderboards/global";
const MAX_ENTRIES = 1000;

function compareEntries(a: RankingEntry, b: RankingEntry): number {
  if (b.totalScore !== a.totalScore) return b.totalScore - a.totalScore;
  return a.achievedAt.localeCompare(b.achievedAt);
}

export async function maybeUpdateLeaderboard(params: {
  uid: string;
  displayName: string | null;
  clearCount: number;
  comboBonus: number;
  timeBonus: number;
  totalScore: number;
  maxCombo: number;
  achievedAt: string;
  bestRunId: string;
}): Promise<boolean> {
  const db = getFirestore();
  const userRef = db.collection("users").doc(params.uid);
  const boardRef = db.doc(LEADERBOARD_DOC);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data() ?? {};
    const prevBest = (user.bestTotalScore as number | undefined) ?? -1;
    const isBetter = params.totalScore > prevBest;
    if (!isBetter) return false;

    const displayName =
      (typeof user.displayName === "string" && user.displayName.trim()) ||
      (params.displayName && params.displayName.trim()) ||
      "";

    tx.set(
      userRef,
      {
        displayName: displayName || user.displayName || null,
        bestClearCount: params.clearCount,
        bestComboBonus: params.comboBonus,
        bestTimeBonus: params.timeBonus,
        bestTotalScore: params.totalScore,
        bestMaxCombo: params.maxCombo,
        bestRunId: params.bestRunId,
        bestAchievedAt: params.achievedAt,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: user.createdAt ?? FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // 名前未設定ならベストのみ保存（ensureDisplayName 後は通常ここに来ない）
    if (!displayName) {
      return true;
    }

    const boardSnap = await tx.get(boardRef);
    const entries = (
      (boardSnap.data()?.entries as RankingEntry[] | undefined) ?? []
    ).filter((e) => e.uid !== params.uid);

    entries.push({
      uid: params.uid,
      name: displayName,
      clearCount: params.clearCount,
      comboBonus: params.comboBonus,
      timeBonus: params.timeBonus,
      totalScore: params.totalScore,
      maxCombo: params.maxCombo,
      achievedAt: params.achievedAt,
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
    return true;
  });
}
