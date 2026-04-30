import 'package:flutter/material.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/piece_type.dart';

/// チュートリアル用駒ウィジェット（簡易版）
class PieceWidget extends StatelessWidget {
  final Piece? piece;
  final double size;

  const PieceWidget({
    super.key,
    this.piece,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50), // 緑色の盤面背景
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2E7D32), // 濃い緑色の枠線
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getPieceColor(),
            border: Border.all(
              color: _getBorderColor(),
              width: 1,
            ),
          ),
          child: piece != null ? _buildPieceContent() : null,
        ),
      ),
    );
  }

  Color _getPieceColor() {
    if (piece == null) {
      return Colors.transparent;
    }

    switch (piece!.type) {
      case PieceType.white:
        return Colors.white;
      case PieceType.black:
        return Colors.black;
      case PieceType.grayPlus:
      case PieceType.grayMinus:
      case PieceType.grayNeutral:
        return Colors.grey.shade600;
      case PieceType.blackWhite:
        return Colors.grey.shade800;
      case PieceType.whiteBlack:
        return Colors.grey.shade300;
    }
  }

  Color _getBorderColor() {
    if (piece?.type.isEntangled == true) {
      return const Color(0xFFEC4899); // ピンク
    }
    return Colors.grey.shade700;
  }

  Widget _buildPieceContent() {
    if (piece!.type.isEntangled) {
      // エンタングル状態: 上下に分割
      return Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: piece!.type == PieceType.blackWhite
                    ? Colors.black
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: piece!.type == PieceType.blackWhite
                    ? Colors.white
                    : Colors.black,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // グレープラスとグレーマイナスの識別マーク
    if (piece!.type == PieceType.grayPlus) {
      return Center(
        child: Text(
          '+',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (piece!.type == PieceType.grayMinus) {
      return Center(
        child: Text(
          '−',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (piece!.type == PieceType.grayNeutral) {
      return const SizedBox.shrink();
    }

    return Container();
  }
}

