import {
  DocumentReference,
  DocumentSnapshot,
  FieldValue,
  Firestore,
  getFirestore,
} from "firebase-admin/firestore";

const MAX_NAME_LENGTH = 12;
/** transaction 内の get 上限に余裕を持たせる */
const MAX_QMASTER_SCAN = 100;
const TA_LEADERBOARD_DOC = "leaderboards/global";
const VS_LEADERBOARD_DOC = "leaderboards/vs_quantum";

export function validatePlayerName(raw: unknown): string {
  if (typeof raw !== "string") {
    throw new Error("name must be a string");
  }
  const trimmed = raw.trim();
  if (trimmed.length < 1 || trimmed.length > MAX_NAME_LENGTH) {
    throw new Error(`name must be 1-${MAX_NAME_LENGTH} characters`);
  }
  for (let i = 0; i < trimmed.length; i++) {
    const code = trimmed.charCodeAt(i);
    if (code === 0x0a || code === 0x0d) {
      throw new Error("name must not contain newlines");
    }
    if (code < 0x20 || code === 0x7f) {
      throw new Error("name must not contain control characters");
    }
    if (trimmed[i] === "/") {
      throw new Error("name must not contain '/'");
    }
  }
  return trimmed;
}

function nameRef(db: Firestore, name: string): DocumentReference {
  return db.collection("playerNames").doc(name);
}

type NamedRankingEntry = {
  uid: string;
  name: string;
  [key: string]: unknown;
};

function renameBoardEntries(
  entries: NamedRankingEntry[] | undefined,
  uid: string,
  name: string,
): { next: NamedRankingEntry[]; changed: boolean } {
  const list = entries ?? [];
  let changed = false;
  const next = list.map((e) => {
    if (e.uid !== uid || e.name === name) return e;
    changed = true;
    return { ...e, name };
  });
  return { next, changed };
}

/** 表示名を予約して users に保存。既存ベストがあれば leaderboard 名も更新 */
export async function setPlayerNameForUid(
  uid: string,
  rawName: string,
): Promise<string> {
  const name = validatePlayerName(rawName);
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const newNameDoc = nameRef(db, name);
  const taBoardRef = db.doc(TA_LEADERBOARD_DOC);
  const vsBoardRef = db.doc(VS_LEADERBOARD_DOC);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data() ?? {};
    const oldName =
      typeof user.displayName === "string" ? user.displayName.trim() : "";

    if (oldName === name) {
      return name;
    }

    const newSnap = await tx.get(newNameDoc);
    if (newSnap.exists && newSnap.data()?.uid !== uid) {
      throw new Error("name already taken");
    }

    let oldRef: DocumentReference | null = null;
    let oldSnap: DocumentSnapshot | null = null;
    if (oldName && oldName !== name) {
      oldRef = nameRef(db, oldName);
      oldSnap = await tx.get(oldRef);
    }

    const taBoardSnap = await tx.get(taBoardRef);
    const vsBoardSnap = await tx.get(vsBoardRef);

    if (oldRef && oldSnap?.exists && oldSnap.data()?.uid === uid) {
      tx.delete(oldRef);
    }

    tx.set(newNameDoc, {
      uid,
      createdAt: newSnap.exists
        ? (newSnap.data()?.createdAt ?? FieldValue.serverTimestamp())
        : FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(
      userRef,
      {
        displayName: name,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: user.createdAt ?? FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (taBoardSnap.exists) {
      const { next, changed } = renameBoardEntries(
        taBoardSnap.data()?.entries as NamedRankingEntry[] | undefined,
        uid,
        name,
      );
      if (changed) {
        tx.set(
          taBoardRef,
          {
            version: 1,
            updatedAt: FieldValue.serverTimestamp(),
            entries: next,
          },
          { merge: true },
        );
      }
    }

    if (vsBoardSnap.exists) {
      const { next, changed } = renameBoardEntries(
        vsBoardSnap.data()?.entries as NamedRankingEntry[] | undefined,
        uid,
        name,
      );
      if (changed) {
        tx.set(
          vsBoardRef,
          {
            version: 1,
            updatedAt: FieldValue.serverTimestamp(),
            entries: next,
          },
          { merge: true },
        );
      }
    }

    return name;
  });
}

/** 未設定なら QMasterN を割り当てて返す */
export async function ensureDisplayName(uid: string): Promise<string> {
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const user = userSnap.data() ?? {};
    const existing =
      typeof user.displayName === "string" ? user.displayName.trim() : "";
    if (existing) {
      return existing;
    }

    const candidates: { name: string; ref: DocumentReference }[] = [];
    for (let n = 1; n <= MAX_QMASTER_SCAN; n++) {
      const name = `QMaster${n}`;
      candidates.push({ name, ref: nameRef(db, name) });
    }

    // Firestore transaction: 全 get を先に実行
    const snaps: DocumentSnapshot[] = [];
    for (const c of candidates) {
      snaps.push(await tx.get(c.ref));
    }

    let chosen: string | null = null;
    let chosenRef: DocumentReference | null = null;
    for (let i = 0; i < candidates.length; i++) {
      const snap = snaps[i];
      if (!snap.exists) {
        chosen = candidates[i].name;
        chosenRef = candidates[i].ref;
        break;
      }
      if (snap.data()?.uid === uid) {
        chosen = candidates[i].name;
        chosenRef = null;
        break;
      }
    }

    if (!chosen) {
      throw new Error("failed to allocate default player name");
    }

    if (chosenRef) {
      tx.set(chosenRef, {
        uid,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(
      userRef,
      {
        displayName: chosen,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: user.createdAt ?? FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return chosen;
  });
}
