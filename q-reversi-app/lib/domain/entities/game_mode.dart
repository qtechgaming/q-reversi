/// ゲームモード
enum GameMode {
  challenge,    // チャレンジモード
  vs,           // VSモード
  freeRun,      // フリーランモード
  study,        // スタディモード
  professional, // プロフェッショナルモード（将来拡張）
}

/// VSモードの種類
enum VsMode {
  human,  // 対人戦
  cpu,    // 対CPU戦
}

/// スタディモードの種類
enum StudyMode {
  intro,    // 量子コンピュータとは？
  study1,   // 1マスで学ぶ量子コンピュータ（1ビット）
  study2,   // 2マスで学ぶ量子コンピュータ（2ビット）
  study3,   // 3マスで学ぶグローバーのアルゴリズム
  epilogue, // 終わりに（注釈・参考書への誘導）
}

/// AI難易度
enum AIDifficulty {
  beginner,     // 初級
  intermediate, // 中級
  advanced,     // 上級
  quantum,      // 量子AI (4-ply minimax with P(win) terminal)
}

/// プレイヤーの色
enum PlayerColor {
  white,  // 白
  black,  // 黒
}

