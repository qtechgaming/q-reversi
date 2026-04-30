# q-reversi Privacy Policy

`index.md` は、GitHub Pagesでそのまま公開できる最小構成のプライバシーポリシーです。

## 使い方

1. `index.md` の角括弧（`[ ]`）を実情報で置換
2. 最終更新日を更新
3. GitHubにPush

## GitHub公開の最小構成

公開専用リポジトリを作る場合の最小ファイルは以下です。

- `index.md`（このポリシー本文）

### 公開手順（Web UI）

1. GitHubで新規リポジトリ作成（https://github.com/qtechgaming/q-reversi-privacy-policy）
2. ルートに `index.md` をアップロード
3. `Settings` > `Pages`
4. `Build and deployment` を `Deploy from a branch`
5. Branchを `main` / Folderを `/ (root)` にして保存
6. 発行されたURLをストア申請情報に設定

### 公開手順（CLI）

```bash
git init
git add index.md
git commit -m "Add privacy policy for q-reversi"
git branch -M main
git remote add origin https://github.com/<your-account>/q-reversi-privacy-policy.git
git push -u origin main
```

Push後にGitHubリポジトリの `Settings` > `Pages` で、`main` / `/ (root)` を指定して公開します。
