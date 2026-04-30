import 'package:flutter/material.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/piece_type.dart';
import '../../core/constants/game_constants.dart';

/// 駒ウィジェット
class PieceWidget extends StatelessWidget {
  final Piece? piece;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double size;
  
  const PieceWidget({
    super.key,
    this.piece,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.size = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPieceColor(),
          border: Border.all(
            color: _getBorderColor(),
            width: isSelected ? 3 : (isHighlighted ? 2 : 1),
          ),
          boxShadow: isSelected || isHighlighted
              ? [
                  BoxShadow(
                    color: _getBorderColor().withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: piece != null
            ? _buildPieceContent()
            : null,
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
        // グレー系は同じベース色（無記号グレーも同じ）
        return Colors.grey.shade600;
      case PieceType.blackWhite:
        return Colors.grey.shade800;
      case PieceType.whiteBlack:
        return Colors.grey.shade300;
    }
  }
  
  Color _getBorderColor() {
    if (isSelected) {
      return const Color(GameConstants.cyan);
    }
    if (isHighlighted) {
      return const Color(GameConstants.neonBlue);
    }
    if (piece?.isEntangled == true) {
      return const Color(GameConstants.pink);
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

