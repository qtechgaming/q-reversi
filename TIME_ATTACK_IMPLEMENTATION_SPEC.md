# QREVERSI TIME ATTACK 実装仕様書

## 0. Cursorへの実装指示

本仕様に従い、既存QREVERSIへ新ゲームモード **TIME ATTACK** を追加する。

対象リポジトリ：

`q-tech-gaming/q-reversi`

Flutterアプリ：

`q-reversi-app/`

### 実装時の最重要原則

1. **既存Challengeモードのゲームロジックを再利用すること。**
2. 盤面操作・ゲート適用・勝利判定などをTIME ATTACK用に複製しないこと。
3. 通常Challenge、VS、Study等の既存挙動を壊さないこと。
4. 不要なリファクタリングをしないこと。
5. 変更範囲をTIME ATTACK実装に必要な最小限に限定すること。
6. 不要なnull check、抽象化、ラッパークラスを増やさないこと。
7. Firebase導入前に、まずローカルだけでTIME ATTACKを完成させること。
8. ゲーム中にネットワーク通信しないこと。
9. ランキング用の値をクライアントからそのまま信用しないこと。
10. 調整可能なゲームパラメータは1か所のConfigへ集約すること。
11. 各Phase完了時にテストを実行し、既存機能へのRegressionがないことを確認すること。
12. 仕様と既存実装が食い違う場合、既存実装を確認した上で、既存アーキテクチャに合わせて最小変更で実現すること。

---

# 1. 背景・目的

既存Challengeモードの問題を利用し、繰り返し遊べるランキング対応のTIME ATTACKモードを追加する。

ゲームの中心体験は、

> 限られた時間の中でランダムに出題されるQリバーシの盤面を連続して解き、どこまで到達できるか競う

というもの。

単なる固定時間制ではなく、問題をクリアすると次の問題の難易度に応じてTIMEが加算される**サバイバル型TIME ATTACK**とする。

---

# 2. 既存実装との関係

現在の`ChallengeLevel`には、

- `level`
- `optimalTurns`
- `availableGates`
- `victoryCondition`
- `initialBoard`
- `comment`

が存在している。特に`optimalTurns`をTIME ATTACKの重要パラメータとして利用する。

Challenge問題は`ChallengeLevelLoader`が既存CSVから読み込んでいる。盤面、使用可能Gate、勝利条件などはこの仕組みをそのまま再利用する。

既存Challengeでは`ChallengeGameService`による勝利判定、`GameProvider`によるGate適用、`GameState.turnCount`によるターン数管理がすでに存在しているため、TIME ATTACKでもこれらを再利用する。

また既存Challengeにはリセット処理が存在し、初期状態を再生成して`GameProvider.resetToState()`している。この基本ロジックも再利用する。

TIME ATTACKは`GameModeSelectionScreen`へ新しいゲームモードとして追加する。

---

# 3. ゲーム基本仕様

## 3.1 ゲーム名称

内部名称：

`TimeAttack`

UI表示：

`TIME ATTACK`

日本語補助表示を付ける場合：

`タイムアタック`

---

## 3.2 使用可能ゲート

TIME ATTACKでも、出題される各問題の`ChallengeLevel.availableGates`（CSVの`available gate`）のみをゲート選択肢とする。

通常Challengeと同様に、問題ごとに許可されたゲート以外は選べない。

全ゲートを常時開放する仕様は採用しない。

---

# 4. 問題構成

## 4.1 使用問題

TIME ATTACK対象は、Challengeの Stage 0 と本編とする。

対象：

```text
0-1 ～ 0-15   （内部levelId: 901 ～ 915）
1 ～ 300
```

合計 315 問。

対象外：

なし（上記以外のCSV問題があればTIME ATTACKへ含めない）

備考：

- CSV上の `0-N` は既存どおり内部番号 `901+(N-1)` として扱う
- Score算出・出題プール・manifest もこの 315 問を対象にする
- Stage 0 も本編と同様に `score = optimalTurns + difficulty` で出題枠へ割当てる

---

## 4.2 Tier と Score

各問題に次の score を定義する。

```text
score = optimalTurns + difficulty
```

`difficulty` は CSV の数値難易度（1〜10）。

TIME ATTACKの進行は Tier 1〜5 のブロックで行い、各ブロック内の出題枠は score 帯で細かく指定する（詳細は #7）。

- Tier 1：問題 1〜10
- Tier 2：問題 11〜20
- Tier 3：問題 21〜30
- Tier 4：問題 31〜40
- Tier 5：問題 41〜50

Tierが高いほど難しい。

---

## 4.3 作者主観難易度

各Challenge問題に作者主観の難易度を追加する。

```dart
enum AuthorDifficulty {
  easy,
  normal,
  hard,
}
```

意味：

### easy

解法が比較的直感的。

### normal

多少の思考・先読みが必要。

### hard

最短解法の発見が難しく、発想・試行錯誤を要する。

重要：

`AuthorDifficulty`は「ターン数の多さ」を評価するものではない。

ターン数はすでに`optimalTurns`として存在するため、

- `optimalTurns` = 操作量
- `AuthorDifficulty` = 解法発見の難しさ

として扱う。

---

# 5. TIME ATTACK用メタデータ

既存のChallenge CSVは独自フォーマットであり、通常Challengeへの影響を避けるため、TIME ATTACK専用メタデータを別ファイルにする。

新規作成：

```text
q-reversi-app/assets/time_attack_metadata.csv
```

形式：

```csv
level,difficulty
1,normal
2,easy
3,hard
...
300,normal
```

`difficulty`は以下のみ許可：

```text
easy
normal
hard
```

通常Challenge用CSVは原則変更しない。

開発初期は未評価問題を`normal`として仮設定してもよいが、最終的には作者が全対象問題（0-1〜0-15 および 1〜300）へ難易度を設定する。

---

# 6. Score / Tier算出

出題枠への割当は、まず score を算出し、#7 の配分表に従って行う。

```text
score = optimalTurns + difficulty
```

TIME加算用の Tier（T1〜T5）は、その問題が何問目として出題されたか（進行枠）で決まる。  
問題そのものに固定 Tier を持たせる必要はない（同じ score 帯の問題でも、出題枠が違えば Tier 倍率は枠に従う）。

Score / 出題枠の決定ロジックは独立したResolver / Generatorへ集約する。

```dart
class TimeAttackScoreResolver {
  int score({
    required int optimalTurns,
    required int difficulty,
  }) => optimalTurns + difficulty;
}

class TimeAttackLevelSequenceGenerator {
  /// 1プレイ分の50問 sequence を生成する
  List<TimeAttackLevelRef> generate(List<ChallengeLevel> pool);
}
```

UI、Repository、GameControllerへ分散させない。

配分表・閾値は Config 化し、後から変更可能にする。

---

# 7. 1プレイの問題構成

1プレイ最大50問。

1問目は初期TIMEのみで始まり、その問題自体へのTIMEボーナス加算はない。  
そのため **1問目は必ず `score = 2` のプールから1題** を選ぶ。

必ず以下の配分・順序とする。

```text
Tier1
  1問目      : Score = 2
  2～5問目   : Score = 3～5
  6～10問目  : Score = 6

Tier2
  11～20問目 : Score = 7～8

Tier3
  21～30問目 : Score = 9～10

Tier4
  31～40問目 : Score = 11～12

Tier5
  41～46問目 : Score = 13～14
  47～50問目 : Score >= 15
```

### 抽選ルール

- 各出題枠の score 条件を満たす問題だけを候補にする
- 同一枠内（例: 2〜5問目、11〜20問目）は候補から非復元抽選し、枠内の順序も shuffle する
- 同一プレイ内で同じ `levelId` を2回出してはならない
- 最終的な50件の `levelId` が unique であることを validation する
- ある出題枠の候補が必要数未満なら TIME ATTACK を開始してはならない
- 不足時に別 score 帯の問題で穴埋めしない

### 参考：現行プール数（0-1〜0-15 + 1〜300）

```text
Score=2        : 5問   → 必要1
Score=3～5     : 33問  → 必要4
Score=6        : 49問  → 必要5
Score=7～8     : 56問  → 必要10
Score=9～10    : 50問  → 必要10
Score=11～12   : 53問  → 必要10
Score=13～14   : 48問  → 必要6
Score>=15      : 21問  → 必要4
```

いずれも必要数を満たす。

---

# 8. ランダム出題

ランダム化は最終的にはCloud Functions側で行う。

サーバーが #7 の配分表に従い、score 帯ごとの必要数を抽選して50問 sequence を作る。

```text
1問目      : Score=2 から1問
2～5問目   : Score=3～5 から4問（枠内shuffle）
6～10問目  : Score=6 から5問（枠内shuffle）
11～20問目 : Score=7～8 から10問（枠内shuffle）
21～30問目 : Score=9～10 から10問（枠内shuffle）
31～40問目 : Score=11～12 から10問（枠内shuffle）
41～46問目 : Score=13～14 から6問（枠内shuffle）
47～50問目 : Score>=15 から4問（枠内shuffle）
```

Flutter側はサーバーから渡された50問の順番をそのまま使用する。

Phase 1のローカル開発時だけ、Flutter側で同じロジックのローカルGeneratorを使用する。

---

# 9. TIME仕様

## 9.1 初期TIME

```text
30.0秒
```

---

## 9.2 MAX TIME

```text
60.0秒
```

どれだけTIMEが加算されても60秒を超えない。

```dart
remainingTime = min(
  remainingTime + bonusTime,
  maxTime,
);
```

---

# 10. TIME加算

**1問目開始時にはTIMEボーナスを加算しない。**  
プレイヤーは初期TIME（30秒）のみで1問目に臨む。

2問目以降は、次の盤面が表示される際に、その問題の`optimalTurns`と（出題枠の）Tierに応じてTIMEを追加する。

## Tier倍率

| Tier | 出題枠 | 1 optimal turnあたり |
|---|---|---:|
| T1 | 1～10問目 | 3.0秒 |
| T2 | 11～20問目 | 2.5秒 |
| T3 | 21～30問目 | 2.0秒 |
| T4 | 31～40問目 | 1.5秒 |
| T5 | 41～50問目 | 1.0秒 |

式：

```text
TimeBonus =
optimalTurns × tierMultiplier
```

例：

```text
T1
optimalTurns = 4

4 × 3.0 = +12秒
```

```text
T4
optimalTurns = 4

4 × 1.5 = +6秒
```

---

# 11. 1問目のTIME

1問目にはTIME追加を行わない。

開始時：

```text
TIME = 30秒
```

のみ。

1問目をクリアし、2問目が表示される直前に初めてTIME BONUSを加える。

---

# 12. 問題遷移

問題クリア時：

```text
現在問題クリア
↓
Timer停止
↓
クリア判定
↓
PERFECT / COMBO判定
↓
短いCLEAR演出
↓
次問題決定
↓
次問題のTIME BONUS加算
↓
60秒でClamp
↓
次盤面生成
↓
操作可能になった時点でTimer再開
```

CLEAR演出や盤面ロード時間はプレイヤーのTIMEから減算しない。

---

# 13. Timerの実装

`Timer.periodic()`のtick回数そのものを残り時間の真値として扱わない。

実時間計測用の`Stopwatch`等をSource of Truthとして利用し、

UI更新だけ一定周期で行う。

目的：

- 描画遅延による誤差を防ぐ
- フレームレート依存を防ぐ
- App backgroundを利用した時間停止を防ぐ

---

# 14. App background時

ゲーム中にアプリがbackgroundへ移動してもTIMEを停止しない。

復帰時に実経過時間を反映する。

backgroundへ移動することでTIME ATTACKを一時停止できてはいけない。

TIMEが0以下なら復帰時に即TIME UPとする。

---

# 15. プレイヤー操作によるDialog

以下を開いてもTIMEは停止しない。

例：

- Gate info
- その他プレイヤーが任意に開くHelp UI

TIMEを止めるのは自動問題遷移など、プレイヤーが制御できない処理のみ。

---

# 16. CLEAR

盤面が既存ChallengeのVictory Conditionを満たした場合、その問題をCLEARとする。

勝利判定は既存：

```dart
ChallengeGameService.checkVictoryCondition(...)
```

相当のロジックを再利用する。

通常ChallengeのVictory DialogはTIME ATTACKでは表示しない。

---

# 17. PERFECT

以下を両方満たす場合のみPERFECT。

```text
turnsUsed == optimalTurns
AND
resetCount == 0
```

Reset後に最短ターンで解いてもPERFECTにはしない。

理由：

Resetによる試行錯誤後の最短解をPERFECTとして扱わないため。

---

# 18. COMBO

PERFECTを連続するとCOMBOが増える。

```text
PERFECT
→ comboStreak + 1

非PERFECT CLEAR
→ comboStreak = 0

RESET
→ comboStreak = 0
```

一度獲得済みのCombo Bonus Pointは失われない。

---

# 19. COMBO BONUS

クリア数とは別にBONUS POINTを持つ。

PERFECTそのものに独立したポイントは付けず、

**PERFECTはCOMBOを発生させる条件**

とする。

初期実装の暫定値：

```text
comboBonus =
currentCombo × 10
```

例：

```text
1 COMBO → +10
2 COMBO → +20
3 COMBO → +30
4 COMBO → +40
...
```

5連続PERFECTした場合の累計：

```text
10 + 20 + 30 + 40 + 50
= 150 BONUS
```

この値は必ずConfig化する。

```text
COMBO_POINT_STEP = 10
```

将来変更可能にする。

---

# 20. Reset

既存Challengeと同様に現在問題の初期盤面へ戻す。

Resetしても：

- TIMEは回復しない
- TIMEは停止しない
- 問題は変更しない

Resetすると：

```text
resetCount += 1
comboStreak = 0
```

その問題では以降PERFECT取得不可。

---

# 21. 終了条件

以下の2つ。

## TIME UP

```text
remainingTime <= 0
```

ゲーム終了。

## ALL CLEAR

```text
clearCount == 50
```

ゲーム終了。

50問を超えて問題を出さない。

---

# 22. ALL CLEAR時の残り時間

50問目をクリアした瞬間の残りTIMEを保存する。

50問目クリア後に次問題用TIMEを加算してはいけない。

---

# 23. TIME BONUS POINT

ALL CLEAR時のみ、残り時間をBONUS POINTへ変換する。

暫定仕様：

```text
0.1秒 = 1 point
```

つまり、

```text
1秒 = 10 points
```

例：

```text
remainingTime = 24.7 sec

TIME BONUS = 247
```

計算：

```dart
timeBonus = remainingTimeMs ~/ 100;
```

TIME UP終了の場合：

```text
timeBonus = 0
```

この倍率もConfig化する。

---

# 24. 最終成績

最終結果は「総合ポイント1個」には統合しない。

メイン評価：

```text
CLEAR数
```

副評価：

```text
BONUS POINT
```

BONUS：

```text
totalBonus =
comboBonus
+
timeBonus
```

表示例：

```text
32 CLEAR

BONUS +860

PERFECT 18
MAX COMBO 7
```

ALL CLEAR：

```text
ALL CLEAR!

50 CLEAR

COMBO BONUS +1,240
TIME BONUS  +327

TOTAL BONUS +1,567
```

---

# 25. ランキング順位

ランキング優先順位：

```text
1. totalScore DESC
2. achievedAt ASC
```

`totalScore` は結果画面と同じく：

```text
CLEAR BONUS + COMBO BONUS + TIME BONUS
```

（`CLEAR BONUS = clearCount × clearBonusPerClear`）

一覧表示はニックネームと TOTAL SCORE のみ。

行タップで詳細を表示する：

```text
CLEAR数
MAX COMBO
COMBO BONUS
TIME BONUS（あれば）
更新日時
```

他プレイヤーの一覧は TOP100 まで。

自分の順位は TOP1000 以内なら表示する。1000位外なら圏外とする。

`achievedAt` は完全同点時だけ使用する内部 tie-break。

先に記録したユーザーを上位とする。

---

# 26. TIME ATTACK Config

ゲーム調整値を散在させない。

Flutter側に例えば：

```text
lib/domain/time_attack/time_attack_config.dart
```

を作成する。

最低限：

```dart
class TimeAttackConfig {
  static const int configVersion = 1;

  static const int totalLevels = 50;
  static const int levelsPerTier = 10;

  static const Duration initialTime = Duration(seconds: 30);
  static const Duration maxTime = Duration(seconds: 60);

  static const int comboPointStep = 10;

  static const int timeBonusUnitMs = 100;
}
```

Tier倍率もConfigへ集約。

Cloud Functions側にも同一Configを用意する。

---

# 27. configVersion

すべてのRunへ：

```text
configVersion
```

を保存する。

初期：

```text
configVersion = 1
```

将来的に、

- TIME倍率変更
- Combo倍率変更
- Tier構成変更
- スコア仕様変更

を行った場合、`configVersion`を上げられる構造にする。

---

# 28. Flutter側アーキテクチャ

既存：

```text
domain/
data/
presentation/
```

構成を維持する。

推奨追加：

```text
lib/
├── domain/
│   └── time_attack/
│       ├── entities/
│       │   ├── time_attack_level.dart
│       │   ├── time_attack_run.dart
│       │   ├── time_attack_level_result.dart
│       │   └── time_attack_result.dart
│       │
│       ├── services/
│       │   ├── time_attack_game_service.dart
│       │   ├── time_attack_tier_resolver.dart
│       │   └── time_attack_level_generator.dart
│       │
│       └── time_attack_config.dart
│
├── data/
│   └── time_attack/
│       ├── time_attack_metadata_loader.dart
│       ├── time_attack_repository.dart
│       └── firebase_time_attack_repository.dart
│
└── presentation/
    ├── providers/
    │   └── time_attack_provider.dart
    │
    └── screens/
        ├── time_attack_start_screen.dart
        ├── time_attack_game_screen.dart
        ├── time_attack_result_screen.dart
        └── time_attack_leaderboard_screen.dart
```

既存構造により自然な配置が存在する場合は既存規則を優先する。

---

# 29. ゲームロジック再利用

TIME ATTACK専用に量子盤面エンジンを作成してはならない。

再利用対象：

- `ChallengeLevel`
- `ChallengeGameService`
- `GameState`
- `GameProvider`
- `BoardWidget`
- `GateButton`
- Gate選択ロジック（各問題の`availableGates`をそのまま使用）
- Victory Condition判定
- Reset処理

TIME ATTACK固有ロジック：

- Timer
- 問題Sequence
- Tier
- Time Bonus
- Combo
- Bonus Point
- 50問進行
- Result
- Cloud submission

だけを追加する。

---

# 30. Challenge進捗との分離

TIME ATTACKで問題をクリアしても、

```text
ChallengeProgress
```

を更新してはならない。

TIME ATTACKクリアによって：

- Challenge level unlock
- Star
- Challenge turnsUsed

などを更新しない。

通常ChallengeとTIME ATTACKは進捗上完全に別扱い。

---

# 31. TIME ATTACK Game State

概念的に以下を持つ。

```dart
class TimeAttackRunState {
  final String? runId;

  final List<TimeAttackLevel> sequence;

  final int currentIndex;
  final int clearCount;

  final Duration remainingTime;

  final int comboStreak;
  final int maxCombo;

  final int comboBonus;
  final int timeBonus;

  final List<TimeAttackLevelResult> results;

  final bool isTransitioning;
  final bool isFinished;
  final bool isAllClear;
}
```

可能ならimmutable stateとして扱う。

---

# 32. Level Result

最低限：

```dart
class TimeAttackLevelResult {
  final int levelId;

  final bool cleared;

  final int turnsUsed;

  final int elapsedMs;

  final int resetCount;
}
```

最後のTIME UP問題については：

```text
cleared = false
```

として保存可能にする。

---

# 33. UI：ゲームモード選択

`GameModeSelectionScreen`へ新規カード：

```text
TIME ATTACK

ランダムな問題を時間内に連続クリア
```

を追加する。

既存カードデザインを踏襲する。

初期仕様ではStage 0クリア後に利用可能とする。

```text
enabled = _isStage0RequirementMet
```

---

# 34. TIME ATTACK Start Screen

表示：

```text
TIME ATTACK

30秒からスタート。
問題を解くとTIMEが追加されます。
全50問、どこまでクリアできる？

[ START ]

[ RANKING ]
```

必要なら簡潔に、

```text
PERFECTを連続するとCOMBO BONUS!
```

も表示。

---

# 35. Game Screen UI

最低限常時表示：

```text
TIME
00:24.8

CLEAR
17 / 50

TIER
2

COMBO
×4
```

盤面付近：

```text
最短 4 TURN
現在 2 TURN
```

を表示。

プレイヤーがPERFECTを狙えるよう`optimalTurns`を隠さない。

---

# 36. CLEAR演出

問題切替時に短時間、

通常：

```text
CLEAR!
TIME +8.0
```

PERFECT：

```text
PERFECT!

4 COMBO
+40 BONUS

TIME +8.0
```

などを表示。

演出時間はTimerから除外。

長いDialogは使用しない。

テンポを阻害しない短いOverlay等を使用する。

---

# 37. TIME警告

残りTIMEが少なくなった場合、視覚的に緊張感を出す。

例：

```text
10秒未満
→ Timer表示を強調

5秒未満
→ さらに強調
```

既存Themeに合わせる。

過剰なAnimationは不要。

---

# 38. Result Screen

TIME UP：

```text
TIME UP

32 CLEAR

BONUS +860

PERFECT 18
MAX COMBO 7

[ RETRY ]
[ RANKING ]
[ EXIT ]
```

ALL CLEAR：

```text
ALL CLEAR!

50 CLEAR

COMBO BONUS +1,240
TIME BONUS +327

BONUS +1,567

[ RETRY ]
[ RANKING ]
[ EXIT ]
```

---

# 39. Firebase採用

クラウド基盤：

```text
Firebase
```

使用サービス：

```text
Firebase Authentication
Cloud Firestore
Cloud Functions for Firebase 2nd gen
Firebase App Check
```

FlutterFire CLIによるFirebase設定を前提とする。`flutterfire configure`により各Flutter platformをFirebase projectへ紐付け、`firebase_options.dart`を生成する構成を使用する。

Cloud FunctionsはTypeScript / Node.js 22を使用する。Node.js 22は現在Cloud Functionsでサポートされているruntimeの一つ。

---

# 40. Firebase依存追加

既存`pubspec.yaml`にはFirebase dependencyが存在しないため新規追加する。

追加：

```text
firebase_core
firebase_auth
cloud_firestore
cloud_functions
firebase_app_check
```

バージョンは既存Flutter SDKと互換性のある最新版を`flutter pub add`で導入する。

Firebase導入だけを理由に既存dependencyを不用意にupgradeしない。

---

# 41. Firebase初期化

現在の`main.dart`は同期的に`runApp()`しているため、Firebase導入時に初期化処理を追加する。

概念：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QReversiApp());
}
```

公式FlutterFire構成に合わせる。

---

# 42. Authentication

ユーザーへログイン操作は要求しない。

アプリ側でFirebase Anonymous Authenticationを利用し、内部UIDを作る。

UX上は：

```text
メールアドレス不要
パスワード不要
ログイン画面なし
```

とする。

Firebase UIDを真のユーザー識別子として使用する。

注意：

Anonymous Authのみの場合、アプリ削除・データ消去等で同一Identityを失う可能性がある。

将来必要になればApple / Google等へのAccount Linkを追加可能な設計に留めるが、今回のScopeには含めない。

---

# 43. Player Name

識別子は Firebase Anonymous Auth の UID。表示名とは別。

Phase 1 では Firebase 未導入のため、同じ形式（28文字英数字）のローカルUIDを発行する。Phase 2 で Auth UID に差し替える。

Player Name はグローバル一意（trim後の完全一致）。UIDで識別し、表示名の重複は許可しない。

未設定時のデフォルト表示名：

```text
QMaster{未使用の最も小さい正整数}
```

例：`QMaster1`, `QMaster2`, `QMaster3`

- `QMaster99999` まで（12文字制限）
- UIDそのものは表示しない
- 初回割当で名前を確定して保存する
- 変更時も一意チェックする（自分の現在名は許可）

TIME ATTACK自体はPlayer Name未設定でもプレイ可能。未設定なら上記デフォルト名を割り当ててランキング掲載する。

初期制約：

```text
trim後 1～12文字
```

禁止：

- 空文字
- 改行
- control character
- 他ユーザーが使用中の名前

サーバー側（Phase 2+）では `setPlayerName` が予約ロックする。Client の一意チェックは補助。最終判定は Server。

---

# 44. Firebase通信方針

ゲーム中はCloud通信しない。

通信タイミング：

```text
ゲーム開始
→ startTimeAttackRun

ゲーム終了
→ submitTimeAttackRun
```

ランキング表示：

```text
leaderboards/global
→ 1 document read
```

のみ。

---

# 45. Cloud Functions構成

新規：

```text
functions/
├── src/
│   ├── index.ts
│   ├── config/
│   │   └── timeAttackConfig.ts
│   ├── time_attack/
│   │   ├── startTimeAttackRun.ts
│   │   ├── submitTimeAttackRun.ts
│   │   ├── setPlayerName.ts
│   │   ├── leaderboardService.ts
│   │   └── scoreCalculator.ts
│   └── generated/
│       └── time_attack_level_catalog.json
├── package.json
└── tsconfig.json
```

Functionsは2nd gen APIを使用する。2nd genの`setGlobalOptions()`等が利用可能。

---

# 46. Region / Cost設定

初期設定：

```text
region = asia-northeast1
minInstances = 0
maxInstances = 2
```

低利用時の固定費を極力発生させないことを優先する。

---

# 47. Server用Level Catalog

FunctionsがTier、optimalTurnsを信用できるよう、Flutterから送信されたTierを使用しない。

既存ChallengeデータからServer用manifestを生成する。

追加：

```text
q-reversi-app/tool/generate_time_attack_catalog.dart
```

入力：

```text
q-reversi_challange-mode.csv
assets/time_attack_metadata.csv
```

出力：

```text
functions/src/generated/time_attack_level_catalog.json
```

形式例：

```json
[
  {
    "levelId": 1,
    "optimalTurns": 2,
    "difficulty": "easy",
    "tier": 1
  }
]
```

Tier Resolverの正式値変更後はmanifestを再生成する。

Source of Truth：

```text
Challenge CSV
+
Time Attack Metadata
```

生成JSONを手編集しない。

---

# 48. startTimeAttackRun

Callable Function：

```text
startTimeAttackRun
```

処理：

```text
Auth確認
↓
Level Catalog読込
↓
T1から10問shuffle抽選
↓
T2から10問
↓
T3から10問
↓
T4から10問
↓
T5から10問
↓
50問sequence作成
↓
runs/{runId}作成
↓
Flutterへsequence返却
```

Response例：

```json
{
  "runId": "abc123",
  "configVersion": 1,
  "initialTimeMs": 30000,
  "maxTimeMs": 60000,
  "comboPointStep": 10,
  "timeBonusUnitMs": 100,
  "levels": [
    {
      "levelId": 15,
      "tier": 1,
      "timeBonusMs": 9000
    }
  ]
}
```

`timeBonusMs`はServer側で計算して返す。

FlutterがTier倍率から独自計算する必要はない。

ただしローカルPhase 1では同じConfigを使用する。

---

# 49. submitTimeAttackRun

Callable Function：

```text
submitTimeAttackRun
```

Clientから送信：

```json
{
  "runId": "...",
  "levelResults": [
    {
      "levelId": 15,
      "cleared": true,
      "turnsUsed": 3,
      "elapsedMs": 7200,
      "resetCount": 0
    }
  ]
}
```

Clientから以下を送って信用してはいけない：

```text
clearCount
comboBonus
timeBonus
totalBonus
remainingTime
```

これらはServer側で再計算する。

---

# 50. Server側結果再計算

ServerはstartRun時に保存したsequenceを使用する。

概念：

```text
remaining = 30000
combo = 0
comboBonus = 0
clear = 0
```

各問題について：

```text
remaining -= elapsedMs
```

TIME UPなら終了。

CLEARなら：

```text
clear++
```

PERFECT条件：

```text
turnsUsed == optimalTurns
&&
resetCount == 0
```

PERFECT：

```text
combo++
comboBonus += combo × COMBO_POINT_STEP
```

それ以外：

```text
combo = 0
```

50 CLEARなら：

```text
timeBonus = remaining / 100ms
```

で終了。

50未満なら次問題の`timeBonusMs`を加算。

```text
remaining =
min(
  remaining + nextLevel.timeBonusMs,
  60000
)
```

この計算結果をOfficial Resultとする。

---

# 51. ClientとServerのTimer差

完全なAnti Cheatを今回のMVPで実現する必要はない。

ただし最低限：

- Server発行Sequence確認
- Sequence順序確認
- levelId一致確認
- optimalTurnsをServer Catalogから取得
- clearCountをServer計算
- ComboをServer計算
- Time BonusをServer計算
- duplicate submit防止

を行う。

Flutterから送られる`elapsedMs`自体の完全な改ざん防止は今回のScope外。

将来的に必要ならGate operation logのServer replayを追加する。

---

# 52. submitの冪等性

同一`runId`が通信リトライで複数回submitされても二重ランキング更新しない。

既にcompletedの場合：

同一Userからのretryであれば既存Official Resultを返す。

---

# 53. 通信失敗

## startRun失敗

ゲーム開始しない。

表示：

```text
TIME ATTACKの開始には通信が必要です。

[再試行]
```

---

## submitRun失敗

ゲーム結果を失わない。

ローカルへpending submissionを保存し、

```text
ランキング送信に失敗しました
[再送信]
```

を表示する。

pending payloadは次回起動時にも再送信可能にする。

SharedPreferencesでもよいが、既存data persistence構造に合う方法を使用する。

---

# 54. Firestore構造

## users

```text
users/{uid}
```

例：

```json
{
  "displayName": "QMaster",

  "bestClearCount": 34,
  "bestBonus": 920,
  "bestRunId": "run123",
  "bestAchievedAt": "...",

  "createdAt": "...",
  "updatedAt": "..."
}
```

名前未設定時：

```text
displayName = null
```

でもよい。

Best Recordは名前未設定でも保存する。

名前設定後にそのBest Recordをランキングへ公開できる。

---

# 55. runs

```text
runs/{runId}
```

1プレイ = 1 document。

50問を50 documentsへ分割しない。

開始時：

```json
{
  "uid": "...",
  "status": "active",
  "configVersion": 1,
  "levelIds": [],
  "startedAt": "..."
}
```

終了後：

```json
{
  "uid": "...",

  "status": "completed",
  "finishReason": "timeUp",

  "configVersion": 1,

  "levelIds": [],

  "clearCount": 34,

  "comboBonus": 920,
  "timeBonus": 0,
  "totalBonus": 920,

  "perfectCount": 19,
  "maxCombo": 6,

  "remainingTimeMs": 0,

  "levelResults": [
    {
      "levelId": 1,
      "cleared": true,
      "turnsUsed": 3,
      "elapsedMs": 5400,
      "resetCount": 0
    }
  ],

  "startedAt": "...",
  "finishedAt": "..."
}
```

`finishReason`：

```text
timeUp
allClear
```

---

# 56. プレイログ

MVPでは全Gate操作ログは保存しない。

1問単位で以下を保存：

```text
levelId
cleared
turnsUsed
elapsedMs
resetCount
```

これにより将来、

- 問題別平均解答時間
- 最短手達成率
- Reset率
- Tier妥当性
- 作者難易度妥当性

を分析できる。

コスト削減のため1問1documentにはしない。

---

# 57. Leaderboard

Firestore：

```text
leaderboards/global
```

1documentのみ。

ランキング原本ではなく、表示高速化用のTOP1000 cacheとする。

---

# 58. leaderboard/global

形式：

```json
{
  "version": 1,
  "updatedAt": "...",

  "entries": [
    {
      "uid": "...",
      "name": "QMaster",
      "clearCount": 50,
      "bonus": 1567,
      "achievedAt": "..."
    }
  ]
}
```

最大1000件。

必ず以下でsort済み：

```text
clearCount DESC
bonus DESC
achievedAt ASC
```

---

# 59. Ranking表示

Firestoreから：

```text
leaderboards/global
```

を1回だけ取得する。

Realtime listenerは使用しない。

```dart
get()
```

相当のone-shot readとする。

受け取った最大1000件のうち、

```text
先頭100件
```

のみ一覧表示する。

---

# 60. 自分の順位

取得したTOP1000内に自分のUIDが存在すれば、

```text
YOU
#327
32 CLEAR
+840 BONUS
```

のように表示可能。

1000位外なら：

```text
TOP 1000 圏外
```

とする。

正確な1001位以下はMVPでは計算しない。

---

# 61. Leaderboard更新

Personal Best更新時だけ`leaderboards/global`を更新する。

BEST比較：

```text
new.clearCount > old.clearCount
```

または：

```text
clearCount同じ
AND
new.bonus > old.bonus
```

完全同点の場合は以前の記録を維持する。

ランキングdoc更新：

```text
既存自分entry削除
↓
新record追加
↓
sort
↓
上位1000だけ残す
↓
transactionで保存
```

1ユーザーにつき最大1entry。

---

# 62. Player Name設定

Callable Function：

```text
setPlayerName
```

処理：

```text
Auth確認
↓
validation
↓
表示名の一意チェック（予約ロック）
↓
旧名の予約を解放
↓
users/{uid}.displayName更新
↓
既存Best Recordがあれば
leaderboards/globalへ反映
```

デフォルト名割当：

```text
QMaster1, QMaster2, … の未使用最小番号を transaction で予約
```

予約は `playerNames/{name}` のような専用docで行い、Clientから直接書けないようにする。

ClientからFirestoreへ直接Player Nameを書かない。

---

# 63. Firestore Security Rules

原則：

```text
Client write禁止
Cloud Functionsからのみwrite
```

概念：

```text
users/{uid}
read: 自分だけ
write: false

runs/{runId}
direct read/write: false

leaderboards/global
read: authenticated user
write: false
```

Anonymous Authでも`request.auth != null`となる前提で利用する。

Cloud Functions Admin SDKからのServer accessを使用する。

---

# 64. App Check

App Checkを導入する。

FlutterではFirebase初期化後にApp Checkをactivateする。公式ドキュメントではAndroidでPlay Integrity、Apple platformでDevice Check/App Attest系、WebでreCAPTCHA系のProviderを利用できる。

開発環境ではDebug Providerを利用する。

本番enforcementは、実機で正常リクエストを確認してから有効化する。

Cloud Functions側Callable FunctionsについてもApp Check enforcementを有効にする。

---

# 65. Cost最優先ルール

目標：

```text
月額 0円 ～ 最大でも概ね1,000円以内
```

そのため以下を守る。

### 禁止

- Gate操作ごとのFirestore write
- 問題ごとのFirestore document作成
- ランキング100件を個別document read
- 不要なRealtime Listener
- minInstances > 0
- ゲーム中のCloud通信
- 不要なCloud Storage利用

### 採用

```text
1 Play
→ 1 run document

Ranking
→ 1 leaderboard document

TOP1000
→ 1 document内array

Leaderboard表示
→ 1 Firestore read
```

---

# 66. levelResults Index

`runs.levelResults`は検索対象にしない。

Firestoreで不要なindexを作らないよう、必要ならsingle-field index exemptionを設定する。

同様に、

```text
leaderboards.entries
```

もquery対象にしないため、不要なindexを避ける。

---

# 67. App Check / Firebase導入順

Firebase公式FlutterセットアップではFlutterFire CLIを使用する。

ただし実装は以下のPhase順とする。

---

# 68. Phase 0：データ構造準備

実装：

- `AuthorDifficulty`
- `time_attack_metadata.csv`
- `TimeAttackMetadataLoader`
- `TimeAttackTierResolver`
- Tier validation
- Server manifest generator

通常Challengeへの影響がないことを確認。

---

# 69. Phase 1：完全ローカルTIME ATTACK

Firebaseを一切使用せず完成させる。

実装：

- TIME ATTACK menu
- Start Screen
- 50問Generator（score帯配分）
- T1～T5進行枠
- 1問目 Score=2 / TIMEボーナスなし
- Timer
- Time Bonus
- 60秒MAX
- PERFECT
- COMBO
- Combo Bonus
- Reset
- Result
- ALL CLEAR
- Time Bonus Point

このPhaseではRepositoryをFake/Local implementationにする。

目標：

**ネットワークなしでTIME ATTACKのゲーム体験を完成させる。**

---

# 70. Phase 2：Firebase基盤

追加：

- Firebase project設定
- FlutterFire
- `firebase_core`
- Anonymous Auth
- Firestore
- Cloud Functions
- 実プロジェクト（`qreversi`）への接続

既存ゲームへの影響を確認。

---

# 71. Phase 3：Cloud Run管理

※ここでいうRunはTIME ATTACKのプレイ単位であり、Google Cloud Run製品ではない。

実装：

```text
startTimeAttackRun
submitTimeAttackRun
```

Local GeneratorからServer Generatorへ切替。

ゲーム中ロジックは変更しない。

---

# 72. Phase 4：User / Ranking

実装：

- Player Name
- users
- leaderboard global
- TOP1000 cache
- TOP100表示
- Personal Best
- 自分の順位

---

# 73. Phase 5：Security

実装：

- Firestore Rules
- App Check
- callable App Check enforcement
- input validation
- duplicate submission validation
- transaction
- pending submit retry

---

# 74. Unit Test

最低限以下をテストする。

## Tier

```text
difficulty parse
Tier Resolver
invalid metadata
```

## Random

```text
50問
1問目は Score=2
各出題枠の score 帯が正しい
重複なし
Tierブロック順序正しい
```

## Timer

```text
initial = 30 sec
max = 60 sec
T1倍率
T2倍率
T3倍率
T4倍率
T5倍率
```

## PERFECT

```text
turn == optimal
reset == 0
→ perfect
```

```text
turn == optimal
reset > 0
→ not perfect
```

## COMBO

```text
perfect連続
combo増加

non-perfect
combo reset

reset
combo reset
```

## Result

```text
TIME UP
ALL CLEAR
Time Bonus
Combo Bonus
```

---

# 75. Backend Test

Cloud Functionsについて最低限：

```text
未認証start拒否
```

```text
T1～T5それぞれ10問
```

```text
同一run内50 level unique
```

```text
sequence改ざん拒否
```

```text
存在しないlevelId拒否
```

```text
duplicate submitが二重更新しない
```

```text
Server側Combo再計算
```

```text
Server側Time再計算
```

```text
Personal Bestのみ更新
```

```text
Leaderboard sort
```

```text
Leaderboard最大1000
```

```text
Player Name validation
```

---

# 76. Regression Test

以下を必ず確認：

- Tutorial起動
- Challenge起動
- Challenge Level読み込み
- Challenge Reset
- Challenge Clear
- Challenge進捗保存
- VS起動
- Study起動
- Web build
- Android build
- iOS build

TIME ATTACK追加により既存挙動を変えない。

---

# 77. Firebase開発環境

開発・検証は **Firebase 実プロジェクト**（`qreversi`）を使用する。

Firebase Emulator Suite は必須としない。ローカル検証用に使ってもよいが、実装・確認の正は実プロジェクトとする。

前提：

- Authentication / Firestore / Cloud Functions を実プロジェクトで有効化する
- Cloud Functions 利用のため Blaze（従量課金）を使用してよい
- 無料枠・無料期間を前提にしつつ、仕様 #65 のコスト抑制は守る
  - `minInstances = 0`
  - ゲーム中の Cloud 通信をしない
  - Ranking は 1 document read
  - Client から Ranking / Run を直接 write しない

App Check の本番 enforcement は、実機で正常リクエストを確認してから有効化する。

---

# 78. 実装完了条件

以下を満たしたらMVP完成。

### Game

- [ ] TIME ATTACKカードから開始できる
- [ ] 初期30秒
- [ ] 最大60秒
- [ ] 1問目は Score=2、TIMEボーナスなし
- [ ] 出題枠ごとの score 帯配分が正しい
- [ ] 全50問
- [ ] 問題重複なし
- [ ] 各問題のavailableGatesのみ選択可能
- [ ] Tier別TIME倍率が正しい
- [ ] CLEARで次問題へ進む
- [ ] PERFECT判定
- [ ] COMBO
- [ ] ResetでCombo Break
- [ ] TIME UP
- [ ] 50問ALL CLEAR
- [ ] Result表示

### Cloud

- [ ] Anonymous Auth
- [ ] startRun
- [ ] submitRun
- [ ] Run log保存
- [ ] Player Name
- [ ] Personal Best保存
- [ ] TOP1000 ranking cache
- [ ] TOP100表示
- [ ] Ranking 1 read

### Security

- [ ] ClientからRanking write不可
- [ ] Client scoreをServerが再計算
- [ ] App Check導入
- [ ] duplicate submit防止

---

# 79. 現時点で未確定のゲームパラメータ

以下は実装を止めない。

必ずConfig / Resolverとして後から変更可能にする。

## TBD-1

出題配分（score 帯と問数目の対応）の微調整。

現行の正式値は #7 を正とする。閾値変更時は Config / Generator のみ更新する。

## TBD-2

Combo Bonus倍率。

暫定：

```text
currentCombo × 10
```

## TBD-3

Remaining Time Bonus倍率。

暫定：

```text
0.1秒 = 1 point
```

---

# 80. 今回Scope外

以下は今回実装しない。

- Apple Login
- Google Login
- Friend Ranking
- Weekly Ranking
- Season Ranking
- Player Profile
- Replay動画
- 全Gate操作のServer replay
- 高度なチート検出
- Cloud Storage
- Push通知
- 管理Web画面
- 問題別統計画面

ただし将来追加しやすいデータ構造にする。

---

# 81. Cursor作業手順

必ず以下の順で実装する。

```text
1.
既存コードを確認

2.
Phase 0
データモデル / Metadata / Tier Resolver

3.
既存テスト実行

4.
Phase 1
Local TIME ATTACK

5.
実機またはSimulatorでゲーム動作確認

6.
既存テスト実行

7.
Phase 2
Firebase導入

8.
Phase 3
startRun / submitRun

9.
Firebase実プロジェクト（qreversi）で確認

10.
Phase 4
Ranking

11.
Phase 5
Security

12.
Flutter analyze

13.
Flutter test

14.
Android/iOS/Webでbuild可能性確認
```

一気に全Phaseを巨大な変更として実装せず、Phase単位で変更を分離する。

---

# 82. Cursorへの最初の実行指示

この仕様書を読んだ後、まず既存リポジトリを調査し、仕様と既存コードの対応関係を確認すること。

その後、**Phase 0とPhase 1のみ**を実装すること。

Firebase部分はPhase 1のローカルTIME ATTACKが完成するまで実装しない。

既存Challengeのゲームロジックを最大限再利用し、通常Challengeへの変更を最小化すること。

Phase 1完了後、以下を報告すること。

1. 変更したファイル一覧
2. 新規追加したファイル一覧
3. Challengeから再利用したロジック
4. TIME ATTACK固有で追加したロジック
5. テスト結果
6. Flutter analyze結果
7. 残っているTODO
8. Phase 2へ進む前に必要なFirebase Console側作業

不明点が実装を完全に阻害しない場合は質問で作業を停止せず、TBD項目をConfig化した上で合理的な暫定値を使用すること。