import { getAuth } from "firebase-admin/auth";
import { FieldValue, Firestore, getFirestore } from "firebase-admin/firestore";

const TA_LEADERBOARD_DOC = "leaderboards/global";
const VS_LEADERBOARD_DOC = "leaderboards/vs_quantum";
const RUN_QUERY_PAGE_SIZE = 400;

type RankingEntry = {
  uid: string;
  name?: string;
  [key: string]: unknown;
};

export type UserLookup = {
  uid?: string;
  name?: string;
};

export type UserDataPreview = {
  uid: string;
  displayName: string | null;
  userDocExists: boolean;
  bestTotalScore: number | null;
  vsQuantumWins: number | null;
  playerNameDocs: string[];
  onTimeAttackLeaderboard: boolean;
  onVsQuantumLeaderboard: boolean;
  runCount: number;
  authExists: boolean;
};

export type DeleteUserDataResult = {
  uid: string;
  displayName: string | null;
  deletedUserDoc: boolean;
  deletedPlayerNameDocs: string[];
  removedFromTimeAttackLeaderboard: boolean;
  removedFromVsQuantumLeaderboard: boolean;
  deletedRunCount: number;
  deletedAuth: boolean;
  authSkipped: boolean;
};

function asEntries(raw: unknown): RankingEntry[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((e): e is RankingEntry => {
    return !!e && typeof e === "object" && typeof (e as RankingEntry).uid === "string";
  });
}

function stripUid(entries: RankingEntry[], uid: string): {
  next: RankingEntry[];
  removed: boolean;
} {
  const next = entries.filter((e) => e.uid !== uid);
  return { next, removed: next.length !== entries.length };
}

async function findUidsByName(db: Firestore, name: string): Promise<string[]> {
  const uids = new Set<string>();

  const nameSnap = await db.collection("playerNames").doc(name).get();
  const nameUid = nameSnap.data()?.uid;
  if (typeof nameUid === "string" && nameUid.trim()) {
    uids.add(nameUid.trim());
  }

  const usersSnap = await db
    .collection("users")
    .where("displayName", "==", name)
    .get();
  for (const doc of usersSnap.docs) {
    uids.add(doc.id);
  }

  const taSnap = await db.doc(TA_LEADERBOARD_DOC).get();
  for (const entry of asEntries(taSnap.data()?.entries)) {
    if (entry.name === name) uids.add(entry.uid);
  }

  const vsSnap = await db.doc(VS_LEADERBOARD_DOC).get();
  for (const entry of asEntries(vsSnap.data()?.entries)) {
    if (entry.name === name) uids.add(entry.uid);
  }

  return [...uids];
}

export async function resolveUid(lookup: UserLookup): Promise<string> {
  const uid = lookup.uid?.trim();
  const name = lookup.name?.trim();
  if (uid) return uid;
  if (!name) {
    throw new Error("uid または name を指定してください");
  }

  const uids = await findUidsByName(getFirestore(), name);
  if (uids.length === 0) {
    throw new Error(`プレイヤー名 "${name}" に一致するデータが見つかりません`);
  }
  if (uids.length > 1) {
    throw new Error(
      `プレイヤー名 "${name}" が複数 UID に一致しました: ${uids.join(", ")}。--uid で指定してください`,
    );
  }
  return uids[0];
}

async function listPlayerNameDocs(
  db: Firestore,
  uid: string,
  displayName: string | null,
): Promise<string[]> {
  const names = new Set<string>();
  if (displayName) names.add(displayName);

  const snap = await db.collection("playerNames").where("uid", "==", uid).get();
  for (const doc of snap.docs) {
    names.add(doc.id);
  }
  return [...names];
}

async function countRuns(db: Firestore, uid: string): Promise<number> {
  const snap = await db.collection("runs").where("uid", "==", uid).count().get();
  return snap.data().count;
}

async function authExists(uid: string): Promise<boolean> {
  try {
    await getAuth().getUser(uid);
    return true;
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "auth/user-not-found") return false;
    throw e;
  }
}

export async function previewUserData(lookup: UserLookup): Promise<UserDataPreview> {
  const db = getFirestore();
  const uid = await resolveUid(lookup);
  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.data() ?? {};
  const displayName =
    typeof user.displayName === "string" && user.displayName.trim()
      ? user.displayName.trim()
      : null;

  const taSnap = await db.doc(TA_LEADERBOARD_DOC).get();
  const vsSnap = await db.doc(VS_LEADERBOARD_DOC).get();

  return {
    uid,
    displayName,
    userDocExists: userSnap.exists,
    bestTotalScore:
      typeof user.bestTotalScore === "number" ? user.bestTotalScore : null,
    vsQuantumWins:
      typeof user.vsQuantumWins === "number" ? user.vsQuantumWins : null,
    playerNameDocs: await listPlayerNameDocs(db, uid, displayName),
    onTimeAttackLeaderboard: asEntries(taSnap.data()?.entries).some(
      (e) => e.uid === uid,
    ),
    onVsQuantumLeaderboard: asEntries(vsSnap.data()?.entries).some(
      (e) => e.uid === uid,
    ),
    runCount: await countRuns(db, uid),
    authExists: await authExists(uid),
  };
}

async function deleteRunsForUid(db: Firestore, uid: string): Promise<number> {
  let deleted = 0;

  for (;;) {
    const snap = await db
      .collection("runs")
      .where("uid", "==", uid)
      .limit(RUN_QUERY_PAGE_SIZE)
      .get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
    if (snap.size < RUN_QUERY_PAGE_SIZE) break;
  }

  return deleted;
}

async function deleteAuthUser(uid: string): Promise<boolean> {
  try {
    await getAuth().deleteUser(uid);
    return true;
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "auth/user-not-found") return false;
    throw e;
  }
}

export async function deleteUserData(
  lookup: UserLookup,
  options: { deleteAuth: boolean } = { deleteAuth: true },
): Promise<DeleteUserDataResult> {
  const db = getFirestore();
  const preview = await previewUserData(lookup);
  const { uid } = preview;

  const playerNameDocs = preview.playerNameDocs;
  const deletedPlayerNameDocs: string[] = [];
  let removedFromTimeAttackLeaderboard = false;
  let removedFromVsQuantumLeaderboard = false;
  let deletedUserDoc = false;

  await db.runTransaction(async (tx) => {
    deletedPlayerNameDocs.length = 0;
    removedFromTimeAttackLeaderboard = false;
    removedFromVsQuantumLeaderboard = false;
    deletedUserDoc = false;
    const userRef = db.collection("users").doc(uid);
    const taRef = db.doc(TA_LEADERBOARD_DOC);
    const vsRef = db.doc(VS_LEADERBOARD_DOC);
    const nameRefs = playerNameDocs.map((name) =>
      db.collection("playerNames").doc(name),
    );

    const userSnap = await tx.get(userRef);
    const taSnap = await tx.get(taRef);
    const vsSnap = await tx.get(vsRef);
    const nameSnaps = [];
    for (const ref of nameRefs) {
      nameSnaps.push(await tx.get(ref));
    }

    if (taSnap.exists) {
      const { next, removed } = stripUid(
        asEntries(taSnap.data()?.entries),
        uid,
      );
      if (removed) {
        removedFromTimeAttackLeaderboard = true;
        tx.set(
          taRef,
          {
            version: 1,
            updatedAt: FieldValue.serverTimestamp(),
            entries: next,
          },
          { merge: true },
        );
      }
    }

    if (vsSnap.exists) {
      const { next, removed } = stripUid(
        asEntries(vsSnap.data()?.entries),
        uid,
      );
      if (removed) {
        removedFromVsQuantumLeaderboard = true;
        tx.set(
          vsRef,
          {
            version: 1,
            updatedAt: FieldValue.serverTimestamp(),
            entries: next,
          },
          { merge: true },
        );
      }
    }

    for (let i = 0; i < nameRefs.length; i++) {
      const snap = nameSnaps[i];
      if (snap.exists && snap.data()?.uid === uid) {
        tx.delete(nameRefs[i]);
        deletedPlayerNameDocs.push(playerNameDocs[i]);
      }
    }

    if (userSnap.exists) {
      deletedUserDoc = true;
      tx.delete(userRef);
    }
  });

  const deletedRunCount = await deleteRunsForUid(db, uid);
  let deletedAuth = false;
  if (options.deleteAuth) {
    deletedAuth = await deleteAuthUser(uid);
  }

  return {
    uid,
    displayName: preview.displayName,
    deletedUserDoc,
    deletedPlayerNameDocs,
    removedFromTimeAttackLeaderboard,
    removedFromVsQuantumLeaderboard,
    deletedRunCount,
    deletedAuth,
    authSkipped: !options.deleteAuth,
  };
}
