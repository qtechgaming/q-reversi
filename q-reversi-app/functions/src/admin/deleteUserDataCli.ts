import { initializeApp } from "firebase-admin/app";
import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import {
  deleteUserData,
  previewUserData,
  type UserLookup,
} from "./userDataDeletion";

const DEFAULT_PROJECT_ID = "qreversi";

function printHelp(): void {
  console.log(`サーバ上の利用者データを削除する管理者用コマンドです。
既定は確認表示のみ（dry-run）です。実際の削除には --execute が必要です。

使い方（Windows では npm run ではなく node を直接実行）:
  node lib/admin/deleteUserDataCli.js --name "プレイヤー名"
  node lib/admin/deleteUserDataCli.js --uid "<Firebase UID>"
  node lib/admin/deleteUserDataCli.js --name "プレイヤー名" --execute
  node lib/admin/deleteUserDataCli.js --uid "<uid>" --execute --yes

詳細手順は functions/README.md を参照。

オプション:
  --name <表示名>   ランキングのプレイヤー名で検索
  --uid <uid>      Firebase Authentication の UID で指定
  --execute        削除を実行（無い場合はプレビューのみ）
  --yes            確認プロンプトを省略
  --keep-auth      Firestore のみ削除し、匿名アカウントは残す
  --project <id>   Firebase プロジェクト ID（既定: ${DEFAULT_PROJECT_ID}）
  --help           このヘルプ
`);
}

function parseArgs(argv: string[]): {
  lookup: UserLookup;
  execute: boolean;
  yes: boolean;
  deleteAuth: boolean;
  projectId: string;
  help: boolean;
} {
  const lookup: UserLookup = {};
  let execute = false;
  let yes = false;
  let deleteAuth = true;
  let projectId = process.env.FIREBASE_PROJECT_ID?.trim() || DEFAULT_PROJECT_ID;
  let help = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") {
      help = true;
      continue;
    }
    if (arg === "--execute") {
      execute = true;
      continue;
    }
    if (arg === "--yes" || arg === "-y") {
      yes = true;
      continue;
    }
    if (arg === "--keep-auth") {
      deleteAuth = false;
      continue;
    }
    if (arg === "--name" || arg === "--uid" || arg === "--project") {
      const value = argv[i + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`${arg} の値がありません`);
      }
      i += 1;
      if (arg === "--name") lookup.name = value;
      if (arg === "--uid") lookup.uid = value;
      if (arg === "--project") projectId = value;
      continue;
    }
    throw new Error(`不明な引数: ${arg}`);
  }

  return { lookup, execute, yes, deleteAuth, projectId, help };
}

function printPreview(preview: Awaited<ReturnType<typeof previewUserData>>): void {
  console.log("対象データの確認:");
  console.log(`  UID:            ${preview.uid}`);
  console.log(`  表示名:         ${preview.displayName ?? "(なし)"}`);
  console.log(`  users ドキュメント: ${preview.userDocExists ? "あり" : "なし"}`);
  console.log(
    `  TA 自己ベスト:  ${preview.bestTotalScore ?? "(なし)"}`,
  );
  console.log(
    `  VS量子AI 勝利:  ${preview.vsQuantumWins ?? "(なし)"}`,
  );
  console.log(
    `  予約名:         ${
      preview.playerNameDocs.length > 0
        ? preview.playerNameDocs.join(", ")
        : "(なし)"
    }`,
  );
  console.log(
    `  TA ランキング:  ${preview.onTimeAttackLeaderboard ? "掲載中" : "未掲載"}`,
  );
  console.log(
    `  VS ランキング:  ${preview.onVsQuantumLeaderboard ? "掲載中" : "未掲載"}`,
  );
  console.log(`  プレイ記録数:   ${preview.runCount}`);
  console.log(`  Auth アカウント: ${preview.authExists ? "あり" : "なし"}`);
}

async function confirm(message: string): Promise<boolean> {
  const rl = readline.createInterface({ input, output });
  try {
    const answer = await rl.question(`${message} [y/N] `);
    return answer.trim().toLowerCase() === "y";
  } finally {
    rl.close();
  }
}

async function main(): Promise<void> {
  let parsed;
  try {
    parsed = parseArgs(process.argv.slice(2));
  } catch (e) {
    console.error(e instanceof Error ? e.message : e);
    printHelp();
    process.exitCode = 1;
    return;
  }

  if (parsed.help) {
    printHelp();
    return;
  }

  if (!parsed.lookup.uid && !parsed.lookup.name) {
    printHelp();
    process.exitCode = 1;
    return;
  }

  initializeApp({ projectId: parsed.projectId });
  console.log(`プロジェクト: ${parsed.projectId}`);

  const preview = await previewUserData(parsed.lookup);
  printPreview(preview);

  if (!parsed.execute) {
    console.log("\nプレビューのみです。削除するには --execute を付けて再実行してください。");
    return;
  }

  if (!parsed.yes) {
    const ok = await confirm(
      `\n上記データをサーバーから削除します${
        parsed.deleteAuth ? "（Auth 含む）" : "（Auth は残す）"
      }。よろしいですか?`,
    );
    if (!ok) {
      console.log("中止しました。");
      return;
    }
  }

  const result = await deleteUserData(parsed.lookup, {
    deleteAuth: parsed.deleteAuth,
  });
  console.log("\n削除結果:");
  console.log(`  UID: ${result.uid}`);
  console.log(`  users: ${result.deletedUserDoc ? "削除" : "対象なし"}`);
  console.log(
    `  予約名: ${
      result.deletedPlayerNameDocs.length > 0
        ? result.deletedPlayerNameDocs.join(", ")
        : "対象なし"
    }`,
  );
  console.log(
    `  TA ランキング: ${
      result.removedFromTimeAttackLeaderboard ? "除外" : "対象なし"
    }`,
  );
  console.log(
    `  VS ランキング: ${
      result.removedFromVsQuantumLeaderboard ? "除外" : "対象なし"
    }`,
  );
  console.log(`  プレイ記録: ${result.deletedRunCount} 件削除`);
  if (result.authSkipped) {
    console.log("  Auth: スキップ (--keep-auth)");
  } else {
    console.log(`  Auth: ${result.deletedAuth ? "削除" : "対象なし"}`);
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exitCode = 1;
});
