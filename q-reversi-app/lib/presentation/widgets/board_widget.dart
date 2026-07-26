import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/forbidden_area.dart';
import 'piece_widget.dart';

/// 盤面セルの駒表示を差し替えるとき用（スタディ画面など）
typedef BoardPieceBuilder = Widget Function(
  Piece piece,
  double size, {
  required bool isSelected,
  required bool isHighlighted,
});

/// ボードウィジェット
class BoardWidget extends StatelessWidget {
  final Board board;
  final List<Position> selectedPositions;
  final List<Position> highlightedPositions;
  /// チュートリアル等の候補マス（選択ハイライトとは別表現）
  final List<Position> suggestedPositions;
  final List<Position> lastTwoBitGatePositions; // 最後に適用された2ビットゲートの位置
  final Function(Position)? onPositionTap;
  final Function(int, String)? onRowSelected; // String: 'left' or 'right'
  final Function(int, String)? onColumnSelected; // String: 'top' or 'bottom'
  final bool enableRowColumnButtons;
  /// `false` のとき、行選択ボタン（盤の左右）を非表示。
  final bool showRowButtons;
  /// `false` のとき、列選択ボタン（盤の上下）のみ非表示。行選択（左右）はそのまま。
  final bool showColumnButtons;
  final GateType? selectedGate;
  final Map<int, bool>? selectedRows;
  final Map<int, bool>? selectedColumns;
  /// チュートリアル等の候補行（選択の緑ハイライトとは別表現）
  final Map<int, bool>? suggestedRows;
  /// チュートリアル等の候補列
  final Map<int, bool>? suggestedColumns;
  final List<ForbiddenArea>? forbiddenAreas; // 禁止領域のリスト
  final double cellSize;
  final Map<String, GlobalKey>? customKeys; // カスタムキー（列選択ボタン、行選択ボタン、盤面セル用）
  /// 指定時は [PieceWidget] の代わりに駒を描画する
  final BoardPieceBuilder? pieceBuilder;

  const BoardWidget({
    super.key,
    required this.board,
    this.selectedPositions = const [],
    this.highlightedPositions = const [],
    this.suggestedPositions = const [],
    this.lastTwoBitGatePositions = const [],
    this.onPositionTap,
    this.onRowSelected,
    this.onColumnSelected,
    this.enableRowColumnButtons = false,
    this.showRowButtons = true,
    this.showColumnButtons = true,
    this.selectedGate,
    this.selectedRows,
    this.selectedColumns,
    this.suggestedRows,
    this.suggestedColumns,
    this.forbiddenAreas,
    this.cellSize = 50,
    this.customKeys,
    this.pieceBuilder,
  });
  
  /// 行が禁止領域かどうか（1ビットゲート選択時のみ）
  bool _isRowForbidden(int row) {
    // 2ビットゲート選択時は禁止領域を表示しない
    if (selectedGate != null && selectedGate!.isTwoBitGate) return false;
    if (forbiddenAreas == null) return false;
    return forbiddenAreas!.any((area) => 
      area.type == ForbiddenAreaType.row && area.row == row
    );
  }
  
  /// 列が禁止領域かどうか（1ビットゲート選択時のみ）
  bool _isColumnForbidden(int col) {
    // 2ビットゲート選択時は禁止領域を表示しない
    if (selectedGate != null && selectedGate!.isTwoBitGate) return false;
    if (forbiddenAreas == null) return false;
    return forbiddenAreas!.any((area) => 
      area.type == ForbiddenAreaType.column && area.column == col
    );
  }
  
  /// 位置が禁止領域かどうか（1ビットゲート選択時のみ）
  bool _isPositionForbidden(Position position) {
    // 2ビットゲート選択時は禁止領域を表示しない
    if (selectedGate != null && selectedGate!.isTwoBitGate) return false;
    if (forbiddenAreas == null) return false;
    for (final area in forbiddenAreas!) {
      if (area.type == ForbiddenAreaType.row && area.row == position.row) {
        return true;
      }
      if (area.type == ForbiddenAreaType.column && area.column == position.col) {
        return true;
      }
      if (area.type == ForbiddenAreaType.fourPieces && area.positions != null) {
        if (area.positions!.any((p) => p == position)) {
          return true;
        }
      }
    }
    return false;
  }

  /// 2ビットゲートの2駒目選択中か（1駒目のみ選択済み）
  bool get _isPickingTwoBitSecond =>
      selectedGate != null &&
      selectedGate!.isTwoBitGate &&
      selectedPositions.length == 1;

  /// 2駒目として選べないマスか（隣接以外）。禁止領域とは別表現（ハッチ）にする。
  bool _isNonAdjacentForTwoBitSecond(Position position) {
    if (!_isPickingTwoBitSecond) return false;
    if (selectedPositions.contains(position)) return false;
    return !position.isAdjacent(selectedPositions.first);
  }

  ButtonStyle _rowColumnButtonStyle({
    required bool isSelected,
    required bool isSuggested,
  }) {
    final isTwoBit = selectedGate != null && selectedGate!.isTwoBitGate;
    Color borderColor;
    if (isTwoBit) {
      borderColor = Colors.transparent;
    } else if (isSelected) {
      borderColor = const Color(0xFF4CAF50);
    } else if (isSuggested) {
      borderColor = Colors.white;
    } else {
      borderColor = const Color(0xFF8B4513);
    }

    Color backgroundColor;
    if (isTwoBit) {
      backgroundColor = Colors.transparent;
    } else {
      // 候補も通常色のまま。強調は白枠＋（ガイド時は）周囲暗幕の切り抜き
      backgroundColor = const Color(0xFFDEB887);
    }

    return ButtonStyle(
      padding: WidgetStateProperty.all(EdgeInsets.zero),
      backgroundColor: WidgetStateProperty.all(backgroundColor),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF8B4513).withOpacity(0.5);
        }
        if (isSelected) return Colors.white;
        return const Color(0xFF8B4513);
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: borderColor,
            width: isSuggested && !isSelected ? 3 : 2,
          ),
        ),
      ),
      elevation: WidgetStateProperty.all(
        isSelected ? 4 : 0,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 縦横一列ボタンを含む盤面全体の外周（2bit選択時も消えない）
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFBDBDBD), // 明るめのグレー（試用）
          width: 4,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showColumnButtons) ...[
            // 列選択ボタン（上側）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: showRowButtons ? 40 + 4 : 0), // 行ボタンの幅分のスペース
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.cols, (col) {
                    final isSelected = selectedColumns?[col] ?? false;
                    final isSuggested = suggestedColumns?[col] ?? false;
                    final isForbidden = _isColumnForbidden(col);
                    // 禁止領域の列ボタンは非表示
                    if (isForbidden) {
                      return Container(
                        width: cellSize,
                        height: 40,
                        margin: const EdgeInsets.all(2),
                      );
                    }
                    final columnTopKey = customKeys?['column_top_$col'];
                    return Container(
                      width: cellSize,
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      child: ElevatedButton(
                        key: columnTopKey,
                        onPressed: enableRowColumnButtons &&
                                (selectedGate == null ||
                                    selectedGate!.isOneBitGate) &&
                                !isForbidden
                            ? () => onColumnSelected?.call(col, 'top')
                            : null,
                        style: _rowColumnButtonStyle(
                          isSelected: isSelected,
                          isSuggested: isSuggested,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
                SizedBox(width: showRowButtons ? 40 + 4 : 0), // 右側行ボタンの幅分のスペース
              ],
            ),
            const SizedBox(height: 4),
          ],
          // 行選択ボタンとボード本体
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 行選択ボタン（左側）
              if (showRowButtons)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.rows, (row) {
                    final isSelected = selectedRows?[row] ?? false;
                    final isSuggested = suggestedRows?[row] ?? false;
                    final isForbidden = _isRowForbidden(row);
                    // 禁止領域の行ボタンは非表示
                    if (isForbidden) {
                      return Container(
                        width: 40,
                        height: cellSize,
                        margin: const EdgeInsets.all(2),
                      );
                    }
                    final rowLeftKey = customKeys?['row_left_$row'];
                    return Container(
                      width: 40,
                      height: cellSize,
                      margin: const EdgeInsets.all(2),
                        child: ElevatedButton(
                        key: rowLeftKey,
                        onPressed: enableRowColumnButtons &&
                                (selectedGate == null || selectedGate!.isOneBitGate) &&
                                !isForbidden
                            ? () => onRowSelected?.call(row, 'left')
                            : null,
                        style: _rowColumnButtonStyle(
                          isSelected: isSelected,
                          isSuggested: isSuggested,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              SizedBox(width: showRowButtons ? 4 : 0),
              // ボードグリッド
              Column(
                children: List.generate(board.rows, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(board.cols, (col) {
                      final position = Position(row, col);
                      final piece = board.getPiece(row, col);
                      final isSelected = selectedPositions.contains(position);
                      // 2ビット時の隣接オレンジは出さない（1ビット適用対象と紛らわしい／2駒選択後も残る）
                      final isHighlighted = highlightedPositions.contains(position) &&
                          !(selectedGate != null && selectedGate!.isTwoBitGate);
                      final isSuggested = suggestedPositions.contains(position) &&
                          !isSelected;
                      final isLastTwoBitGate = lastTwoBitGatePositions.contains(position);
                      final isForbidden = _isPositionForbidden(position);
                      final isNonAdjacentForTwoBit =
                          _isNonAdjacentForTwoBitSecond(position);
                      
                      // 2ビットゲートの場合、1駒目と2駒目を区別
                      final selectedIndex = selectedPositions.indexOf(position);
                      final isFirstPiece = selectedIndex == 0;
                      final isSecondPiece = selectedIndex == 1;
                      // 2ビットゲートで2マス選択の場合のみ1駒目と2駒目を区別
                      final isTwoBitGateSelection = selectedGate != null &&
                          selectedGate!.isTwoBitGate &&
                          selectedPositions.length == 2;
                      const twoBitSecondColor = Color(GameConstants.cyan);
                      
                      final cellKey = customKeys?['cell_${row}_$col'];
                      return GestureDetector(
                        onTap: isForbidden ? null : () => onPositionTap?.call(position),
                        child: Container(
                          key: cellKey,
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isForbidden
                                      ? Colors.grey.withOpacity(0.5) // 禁止領域はグレーアウト
                                      : isLastTwoBitGate
                                          ? Colors.cyan.withOpacity(0.5)
                                          : isSelected
                                              ? (isTwoBitGateSelection
                                                  ? (isFirstPiece
                                                      ? Colors.orange.withOpacity(0.6)
                                                      : twoBitSecondColor.withOpacity(0.6))
                                                  : Colors.orange.withOpacity(0.5))
                                              : isHighlighted
                                                  ? Colors.orange.withOpacity(0.5)
                                                  : const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isForbidden
                                        ? Colors.grey
                                        : isLastTwoBitGate
                                            ? Colors.cyan
                                            : isSelected
                                                ? (isTwoBitGateSelection
                                                    ? (isFirstPiece
                                                        ? Colors.orange
                                                        : twoBitSecondColor)
                                                    : Colors.orange)
                                                : isHighlighted
                                                    ? Colors.orange
                                                    : isSuggested
                                                        ? Colors.white
                                                        : const Color(0xFF4CAF50),
                                    width: isSuggested ? 3.5 : 3,
                                  ),
                                  boxShadow:
                                      (isSelected || isHighlighted) && !isForbidden
                                          ? [
                                              BoxShadow(
                                                color: (isTwoBitGateSelection &&
                                                            isSecondPiece
                                                        ? twoBitSecondColor
                                                        : Colors.orange)
                                                    .withOpacity(0.6),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                ),
                                child: piece != null
                                    ? Opacity(
                                        opacity: isForbidden ? 0.5 : 1.0,
                                        child: pieceBuilder != null
                                            ? pieceBuilder!(
                                                piece,
                                                cellSize - 8,
                                                // 2駒目も選択扱い → 駒枠は水色（GameConstants.cyan）
                                                isSelected: isSelected,
                                                isHighlighted: isHighlighted,
                                              )
                                            : PieceWidget(
                                                piece: piece,
                                                isSelected: isSelected,
                                                isHighlighted: isHighlighted,
                                                size: cellSize - 8,
                                              ),
                                      )
                                    : null,
                              ),
                              // 2bit隣接外（1駒目のみ選択時）: 斜線ではなく塗りつぶしグレー（全体に50%）
                              if (isNonAdjacentForTwoBit)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.50),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              SizedBox(width: showRowButtons ? 4 : 0),
              // 行選択ボタン（右側）
              if (showRowButtons)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.rows, (row) {
                    final isSelected = selectedRows?[row] ?? false;
                    final isSuggested = suggestedRows?[row] ?? false;
                    final isForbidden = _isRowForbidden(row);
                    // 禁止領域の行ボタンは非表示
                    if (isForbidden) {
                      return Container(
                        width: 40,
                        height: cellSize,
                        margin: const EdgeInsets.all(2),
                      );
                    }
                    return Container(
                      width: 40,
                      height: cellSize,
                      margin: const EdgeInsets.all(2),
                        child: ElevatedButton(
                        onPressed: enableRowColumnButtons &&
                                (selectedGate == null || selectedGate!.isOneBitGate) &&
                                !isForbidden
                            ? () => onRowSelected?.call(row, 'right')
                            : null,
                        style: _rowColumnButtonStyle(
                          isSelected: isSelected,
                          isSuggested: isSuggested,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
            ],
          ),
          if (showColumnButtons) ...[
            const SizedBox(height: 4),
            // 列選択ボタン（下側）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: showRowButtons ? 40 + 4 : 0), // 行ボタンの幅分のスペース
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.cols, (col) {
                    final isSelected = selectedColumns?[col] ?? false;
                    final isSuggested = suggestedColumns?[col] ?? false;
                    final isForbidden = _isColumnForbidden(col);
                    // 禁止領域の列ボタンは非表示
                    if (isForbidden) {
                      return Container(
                        width: cellSize,
                        height: 40,
                        margin: const EdgeInsets.all(2),
                      );
                    }
                    return Container(
                      width: cellSize,
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      child: ElevatedButton(
                        onPressed: enableRowColumnButtons &&
                                (selectedGate == null ||
                                    selectedGate!.isOneBitGate) &&
                                !isForbidden
                            ? () => onColumnSelected?.call(col, 'bottom')
                            : null,
                        style: _rowColumnButtonStyle(
                          isSelected: isSelected,
                          isSuggested: isSuggested,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
                SizedBox(width: showRowButtons ? 40 + 4 : 0), // 右側行ボタンの幅分のスペース
              ],
            ),
          ],
        ],
      ),
    );
  }
}

