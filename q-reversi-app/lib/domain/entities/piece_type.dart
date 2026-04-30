/// 駒の種類
enum PieceType {
  white, // 白 |0⟩
  black, // 黒 |1⟩
  grayPlus, // グレープラス |+⟩
  grayMinus, // グレーマイナス |-⟩
  blackWhite, // ブラックホワイト（エンタングル）
  whiteBlack, // ホワイトブラック（エンタングル）
  grayNeutral, // 無記号グレー（スタディ2など：上記で表せない重ね合わせ等）
}

extension PieceTypeExtension on PieceType {
  /// 文字列表現
  String get symbol {
    switch (this) {
      case PieceType.white:
        return 'W';
      case PieceType.black:
        return 'B';
      case PieceType.grayPlus:
        return '+';
      case PieceType.grayMinus:
        return '-';
      case PieceType.blackWhite:
        return 'BW';
      case PieceType.whiteBlack:
        return 'WB';
      case PieceType.grayNeutral:
        return 'G';
    }
  }

  /// CSVから読み込み
  static PieceType? fromString(String str) {
    switch (str.trim().toUpperCase()) {
      case 'W':
        return PieceType.white;
      case 'B':
        return PieceType.black;
      case '+':
        return PieceType.grayPlus;
      case '-':
        return PieceType.grayMinus;
      case 'BW':
        return PieceType.blackWhite;
      case 'WB':
        return PieceType.whiteBlack;
      case 'GN':
      case 'G':
        return PieceType.grayNeutral;
      default:
        return null;
    }
  }

  /// エンタングル状態かどうか
  bool get isEntangled {
    return this == PieceType.blackWhite || this == PieceType.whiteBlack;
  }

  /// 確定状態かどうか（白または黒）
  bool get isDetermined {
    return this == PieceType.white || this == PieceType.black;
  }

  /// 重ね合わせ状態かどうか
  bool get isSuperposition {
    return this == PieceType.grayPlus || this == PieceType.grayMinus;
  }
}
