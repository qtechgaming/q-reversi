import 'dart:math';
import '../entities/piece_type.dart';
import '../entities/game_state.dart';

/// 測定サービス
class MeasurementService {
  final Random _random = Random();
  
  /// 測定操作を実行
  GameState measure(GameState gameState) {
    var newBoard = gameState.board;
    final measuredPairs = <String>{};
    
    // エンタングルペアを先に処理
    for (final pair in gameState.entangledPairs) {
      if (measuredPairs.contains(pair.id)) continue;
      
      final piece1 = newBoard.getPiece(pair.position1.row, pair.position1.col);
      final piece2 = newBoard.getPiece(pair.position2.row, pair.position2.col);
      
      if (piece1 != null && piece2 != null && 
          piece1.entangledPairId == pair.id && 
          piece2.entangledPairId == pair.id) {
        // エンタングルペアを測定
        // 1駒目を測定（50%で白/黒に確定）
        final isWhite = _random.nextBool();
        final measuredType1 = isWhite ? PieceType.white : PieceType.black;
        
        // 2駒目は、エンタングル状態の組み合わせに応じて確定
        PieceType measuredType2;
        
        // 同じエンタングル状態（blackWhite/blackWhite または whiteBlack/whiteBlack）の場合
        // → 両方とも同じ色になる（50%で黒/黒、50%で白/白）
        if ((piece1.type == PieceType.blackWhite && piece2.type == PieceType.blackWhite) ||
            (piece1.type == PieceType.whiteBlack && piece2.type == PieceType.whiteBlack)) {
          measuredType2 = measuredType1; // 1駒目と同じ色
        }
        // 異なるエンタングル状態（blackWhite/whiteBlack または whiteBlack/blackWhite）の場合
        // → 反対の色になる（50%で黒/白、50%で白/黒）
        else if ((piece1.type == PieceType.blackWhite && piece2.type == PieceType.whiteBlack) ||
                 (piece1.type == PieceType.whiteBlack && piece2.type == PieceType.blackWhite)) {
          measuredType2 = isWhite ? PieceType.black : PieceType.white; // 1駒目と反対の色
        }
        // 予期しない状態の場合（通常は発生しない）
        else {
          measuredType2 = measuredType1;
        }
        
        final newPiece1 = piece1.copyWith(
          type: measuredType1,
          entangledPairId: null,
        );
        final newPiece2 = piece2.copyWith(
          type: measuredType2,
          entangledPairId: null,
        );
        
        newBoard = newBoard.setPiece(
          pair.position1.row,
          pair.position1.col,
          newPiece1,
        );
        newBoard = newBoard.setPiece(
          pair.position2.row,
          pair.position2.col,
          newPiece2,
        );
        
        measuredPairs.add(pair.id);
      }
    }
    
    // 残りの駒を測定
    for (int r = 0; r < newBoard.rows; r++) {
      for (int c = 0; c < newBoard.cols; c++) {
        final piece = newBoard.getPiece(r, c);
        if (piece == null || piece.isEntangled) continue;
        
        final measuredType = _measurePiece(piece.type);
        if (measuredType != piece.type) {
          final newPiece = piece.copyWith(type: measuredType);
          newBoard = newBoard.setPiece(r, c, newPiece);
        }
      }
    }
    
    return gameState.copyWith(board: newBoard);
  }
  
  /// 駒を測定
  PieceType _measurePiece(PieceType type) {
    switch (type) {
      case PieceType.white:
      case PieceType.black:
        // 確定状態はそのまま
        return type;
        
      case PieceType.grayPlus:
      case PieceType.grayMinus:
      case PieceType.grayNeutral:
        // 50%の確率で白か黒に反転
        return _random.nextBool() ? PieceType.white : PieceType.black;
        
      case PieceType.blackWhite:
      case PieceType.whiteBlack:
        // 50%の確率で白か黒に反転
        return _random.nextBool() ? PieceType.white : PieceType.black;
    }
  }
}

