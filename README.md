# Q-Reversi: Quantum Reversi

量子ゲート操作で盤面を操る新感覚リバーシ。

**▶ Play:** https://qtechgaming.github.io/q-reversi/

## AIレベル
| レベル | 説明 |
|--------|------|
| 初級 | ランダム |
| 中級 | 1手先読み（クラシカル評価） |
| 上級 | 1手先読み（量子測定予測付き） |
| **量子AI** | **4手先読み minimax + 量子P(win)評価関数 (QAZ-QR)** |

## 量子AI (QAZ-QR) について

FourPlyMiniMaxQR アルゴリズムを Dart に移植:

- **深さ1**: 全合法手をクラシカル評価でスコアリング → 上位 K1=10 を選択
- **深さ2**: 相手の最善手（greedy、クラシカル評価最小化）
- **深さ3**: 上位 K3=3 をクラシカル評価でスコアリング
- **深さ4**: 相手の「タイ手悲観的」評価 → 同点手を全探索し最悪 P(win) を採用

**終端評価関数**: Φ(μ / √n_gray)
- μ = 確定白駒数 − 確定黒駒数
- n_gray = 重ね合わせ駒数（GRAY_PLUS / GRAY_MINUS）
- エンタングル駒（WHITE_BLACK / BLACK_WHITE）は寄与ゼロ

Python ベンチマーク (q-reversi-integration):
- vs 初級: **100%** (target 95%) ✓
- vs 中級: **82.5%** (target 80%) ✓
- vs 上級: **70%** (target 65%) ✓

## セットアップ (ローカル実行)

```bash
cd q-reversi-app
flutter pub get
flutter run -d chrome
```

## GitHub Pages 設定

Settings → Pages → Branch: `main` / Folder: `/docs` に設定してください。
`q-reversi-app/` への変更を push すると自動でビルド・デプロイされます。

## License

This project is licensed under the Apache License 2.0.
See `LICENSE` for details.
