# NGワードリスト生成

プレイヤー表示名の初期 NG ワードを生成する。

## ソース

1. [MosasoM/inappropriate-words-ja](https://github.com/MosasoM/inappropriate-words-ja) (MIT)  
   - `Sexual.txt` / `Offensive.txt`
2. [shutterstock/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words](https://github.com/shutterstock/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words)  
   - `ja` / `en`
3. アプリ予約語（`admin` / `運営` / `公式` など）

誤検知しやすい語（例: `イク`, `sexy`, 短すぎる英単語）はスクリプト内で除外している。

## 使い方

```bash
cd functions/scripts
curl -sL https://raw.githubusercontent.com/MosasoM/inappropriate-words-ja/master/Sexual.txt -o _sexual.txt
curl -sL https://raw.githubusercontent.com/MosasoM/inappropriate-words-ja/master/Offensive.txt -o _offensive.txt
curl -sL https://raw.githubusercontent.com/shutterstock/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/ja -o _ss_ja.txt
curl -sL https://raw.githubusercontent.com/shutterstock/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/en -o _ss_en.txt
cd ..
npm run generate:ng-words
npm run build
```

出力:

- `src/time_attack/ngWords.ts`（サーバー本命）
- `../lib/domain/time_attack/ng_word_list.dart`（クライアント先行チェック）
