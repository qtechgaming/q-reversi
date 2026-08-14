# Cloud Functions

タイムアタック／VS量子AIランキング用の Firebase Cloud Functions です。

```bash
npm install
npm run build
npm run deploy
```

## 利用者データの削除（運営者向け）

メール等で削除の申し入れがあったとき、サーバー上の該当データを削除するコマンドです。
この手順は GitHub 上で公開される前提です。**認証情報・サービスアカウントキー・秘密鍵はリポジトリに置かないでください。**

削除できるのはサーバー上のデータのみです。

- 表示名
- タイムアタック／VS量子AIのランキング記録
- 当該ユーザーのプレイ記録
- Firebase の匿名アカウント

端末内データは削除できません。依頼者には、アプリの削除または端末のストレージ消去を案内してください。

### 前提

Firebase プロジェクトの管理者権限が必要です。ローカルでは Application Default Credentials などで認証します。認証情報の置き場所や取得方法は、この README には書きません。

### 使い方

既定はプレビューのみです。内容を確認してから `--execute` を付けます。

```bash
cd q-reversi-app/functions
npm install

# プレイヤー名で確認（削除しない）
npm run delete-user -- --name "プレイヤー名"

# UID で確認
npm run delete-user -- --uid "<Firebase UID>"

# 確認のうえ削除
npm run delete-user -- --name "プレイヤー名" --execute
```

問い合わせでは、ランキングに表示されているプレイヤー名をもらうと特定しやすいです。
同名が複数アカウントに紐づく場合は `--uid` で指定してください。
