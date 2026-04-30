import 'package:equatable/equatable.dart';
import 'piece.dart';

/// 盤面
class Board extends Equatable {
  final List<List<Piece?>> pieces;
  final int rows;
  final int cols;
  
  const Board({
    required this.pieces,
    required this.rows,
    required this.cols,
  });
  
  /// 8×8ボードを作成
  factory Board.create8x8() {
    return Board(
      pieces: List.generate(8, (r) => List.generate(8, (c) => null)),
      rows: 8,
      cols: 8,
    );
  }
  
  /// 1×1ボードを作成（スタディ1）
  factory Board.create1x1() {
    return Board(
      pieces: List.generate(1, (r) => List.generate(1, (c) => null)),
      rows: 1,
      cols: 1,
    );
  }
  
  /// 1×2ボードを作成（スタディ2）
  factory Board.create1x2() {
    return Board(
      pieces: List.generate(1, (r) => List.generate(2, (c) => null)),
      rows: 1,
      cols: 2,
    );
  }

  /// 1×3ボードを作成（スタディ3）
  factory Board.create1x3() {
    return Board(
      pieces: List.generate(1, (r) => List.generate(3, (c) => null)),
      rows: 1,
      cols: 3,
    );
  }
  
  /// 1×4ボードを作成（スタディ3）
  factory Board.create1x4() {
    return Board(
      pieces: List.generate(1, (r) => List.generate(4, (c) => null)),
      rows: 1,
      cols: 4,
    );
  }
  
  /// 指定位置の駒を取得
  Piece? getPiece(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      return null;
    }
    return pieces[row][col];
  }
  
  /// 指定位置に駒を設定
  Board setPiece(int row, int col, Piece? piece) {
    final newPieces = pieces.map((row) => List<Piece?>.from(row)).toList();
    newPieces[row][col] = piece;
    return Board(pieces: newPieces, rows: rows, cols: cols);
  }
  
  /// すべての駒を取得
  List<Piece> getAllPieces() {
    final result = <Piece>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final piece = pieces[r][c];
        if (piece != null) {
          result.add(piece);
        }
      }
    }
    return result;
  }
  
  /// 位置が有効かどうか
  bool isValidPosition(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }
  
  @override
  List<Object?> get props => [pieces, rows, cols];
}

