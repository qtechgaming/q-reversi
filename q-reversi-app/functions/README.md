# Cloud Functions

タイムアタック／VS量子AIランキング用の Firebase Cloud Functions です。

```bash
npm install
npm run build
npm run deploy
```

## 利用者データの削除（運営者向け）

メール等で削除の申し入れがあったとき、サーバー上の該当データを削除する手順です。
この手順は GitHub 上で公開される前提です。**認証情報・サービスアカウントキー・秘密鍵はリポジトリに置かないでください。**

公式の `firebase` CLI には Auth ユーザー削除コマンドはありません（`auth:export` は一覧書き出しのみ）。このリポジトリの管理者スクリプトを使います。

削除できるのはサーバー上のデータのみです。

- `users/{uid}` の表示名・自己ベスト
- 予約名（`playerNames`）
- タイムアタック／VS量子AIのランキング行
- 当該ユーザーのプレイ記録（`runs`）
- Firebase の匿名アカウント

端末内データは削除できません。依頼者には、アプリの削除または端末のストレージ消去を案内してください。

### 前提

- Firebase プロジェクト `qreversi` の管理者権限
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)（`gcloud`）
- Node.js（スクリプト実行用）

### 1. 認証

```powershell
gcloud auth application-default login
gcloud auth application-default set-quota-project qreversi
```

ブラウザで管理者アカウントを許可します。2 行目は、手元の ADC が Auth API（Identity Toolkit）を呼ぶためのクォータプロジェクト指定です。未設定だと次のエラーで止まり、**削除は実行されません**。

```text
identitytoolkit.googleapis.com API requires a quota project
Could not load the default credentials
```

### 2. 対象の確認（削除しない）

Windows の PowerShell では `npm run delete-user -- --name "..."` を使わないでください。npm が `--name` を自分のオプションとして飲み、`不明な引数: プレイヤー名` で失敗します（この時点でも削除されていません）。

スクリプト名は `deleteUserDataCli.js` です（`Date` ではない）。

```powershell
cd q-reversi-app\functions
npm install
npx tsc
node lib/admin/deleteUserDataCli.js --name "プレイヤー名"
```

UID が分かっている場合:

```powershell
node lib/admin/deleteUserDataCli.js --uid "<Firebase UID>"
```

問い合わせでは、ランキングに表示されているプレイヤー名をもらうと特定しやすいです。
同名が複数アカウントに紐づく場合は、プレビューに出た UID を `--uid` で指定してください。

UID の確認は Firebase Console の Authentication、または次でもできます。

```powershell
cd q-reversi-app
firebase auth:export users.json --format=json --project qreversi
```

### 3. 削除

プレビューで UID・ランキング掲載を確認してから実行します。確認プロンプトで `y` を入力します。

```powershell
node lib/admin/deleteUserDataCli.js --name "プレイヤー名" --execute
```

プロンプトを省略する場合だけ `--yes` を付けます。Auth は残して Firestore だけ消す場合は `--keep-auth` を付けます。

成功すると `対象データの確認:` のあと `削除結果:` が出ます。ヘルプだけ出た、`MODULE_NOT_FOUND`、`default credentials`、`quota project` のいずれかなら、サーバーデータはまだ残っています。

`firebase firestore:delete users/<uid>` はユーザー文書だけ消し、ランキング配列からは外れません。使わないでください。
