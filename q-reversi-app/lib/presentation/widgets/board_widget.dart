import 'package:flutter/material.dart';
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
  
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
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
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          backgroundColor: WidgetStateProperty.all(
                            (selectedGate != null && selectedGate!.isTwoBitGate)
                                ? Colors.transparent // 2ビットゲート選択時は背景色無し
                                : const Color(0xFFDEB887), // 盤面の背景色と同じ
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Color(0xFF8B4513).withOpacity(0.5);
                            }
                            return isSelected
                                ? Colors.white
                                : const Color(0xFF8B4513);
                          }),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: (selectedGate != null &&
                                        selectedGate!.isTwoBitGate)
                                    ? Colors.white
                                    : (isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF8B4513)),
                                width: 2,
                              ),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(isSelected ? 4 : 0),
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
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          backgroundColor: WidgetStateProperty.all(
                            (selectedGate != null && selectedGate!.isTwoBitGate)
                                ? Colors.transparent // 2ビットゲート選択時は背景色無し
                                : const Color(0xFFDEB887), // 盤面の背景色と同じ
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Color(0xFF8B4513).withOpacity(0.5);
                            }
                            return isSelected
                                ? Colors.white
                                : const Color(0xFF8B4513);
                          }),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: (selectedGate != null && selectedGate!.isTwoBitGate)
                                    ? Colors.white
                                    : (isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF8B4513)),
                                width: 2,
                              ),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(isSelected ? 4 : 0),
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
                      final isHighlighted = highlightedPositions.contains(position);
                      final isLastTwoBitGate = lastTwoBitGatePositions.contains(position);
                      final isForbidden = _isPositionForbidden(position);
                      
                      // 2ビットゲートの場合、1駒目と2駒目を区別
                      final selectedIndex = selectedPositions.indexOf(position);
                      final isFirstPiece = selectedIndex == 0;
                      // 2ビットゲートで2マス選択の場合のみ1駒目と2駒目を区別
                      final isTwoBitGateSelection = selectedGate != null &&
                          selectedGate!.isTwoBitGate &&
                          selectedPositions.length == 2;
                      
                      final cellKey = customKeys?['cell_${row}_$col'];
                      return GestureDetector(
                        onTap: isForbidden ? null : () => onPositionTap?.call(position),
                        child: Container(
                          key: cellKey,
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isForbidden
                                ? Colors.grey.withOpacity(0.5) // 禁止領域はグレーアウト
                                : isLastTwoBitGate
                                    ? Colors.cyan.withOpacity(0.5) // 最後に適用された2ビットゲートの位置はシアンでハイライト
                                    : isSelected
                                        ? (isTwoBitGateSelection
                                            ? (isFirstPiece
                                                ? Colors.orange.withOpacity(0.6)
                                                : Colors.blue.withOpacity(0.6))
                                            : Colors.orange.withOpacity(0.5))
                                        : isHighlighted
                                            ? Colors.orange.withOpacity(0.5)
                                            : const Color(0xFF4CAF50), // 緑色の背景
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isForbidden
                                  ? Colors.grey // 禁止領域はグレーの枠線
                                  : isLastTwoBitGate
                                      ? Colors.cyan // 最後に適用された2ビットゲートの位置はシアンの枠線
                                      : isSelected
                                          ? (isTwoBitGateSelection
                                              ? (isFirstPiece
                                                  ? Colors.orange
                                                  : Colors.blue)
                                              : Colors.orange)
                                          : isHighlighted
                                              ? Colors.orange
                                              : const Color(0xFF4CAF50), // 緑色の枠線
                              width: isLastTwoBitGate
                                  ? 3 // 最後に適用された2ビットゲートの位置は太い枠線
                                  : isSelected
                                      ? 3
                                      : (isHighlighted ? 3 : 3),
                            ),
                            boxShadow: (isSelected || isHighlighted) && !isForbidden
                                ? [
                                    BoxShadow(
                                      color: (isTwoBitGateSelection && isSelected
                                          ? (isFirstPiece
                                              ? Colors.orange
                                              : Colors.blue)
                                          : Colors.orange).withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: piece != null
                              ? Opacity(
                                  opacity: isForbidden ? 0.5 : 1.0, // 禁止領域は半透明
                                  child: pieceBuilder != null
                                      ? pieceBuilder!(
                                          piece,
                                          cellSize - 8,
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
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          backgroundColor: WidgetStateProperty.all(
                            (selectedGate != null && selectedGate!.isTwoBitGate)
                                ? Colors.transparent // 2ビットゲート選択時は背景色無し
                                : const Color(0xFFDEB887), // 盤面の背景色と同じ
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Color(0xFF8B4513).withOpacity(0.5);
                            }
                            return isSelected
                                ? Colors.white
                                : const Color(0xFF8B4513);
                          }),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: (selectedGate != null && selectedGate!.isTwoBitGate)
                                    ? Colors.white
                                    : (isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF8B4513)),
                                width: 2,
                              ),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(isSelected ? 4 : 0),
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
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          backgroundColor: WidgetStateProperty.all(
                            (selectedGate != null && selectedGate!.isTwoBitGate)
                                ? Colors.transparent // 2ビットゲート選択時は背景色無し
                                : const Color(0xFFDEB887), // 盤面の背景色と同じ
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return const Color(0xFF8B4513).withOpacity(0.5);
                            }
                            return isSelected
                                ? Colors.white
                                : const Color(0xFF8B4513);
                          }),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: (selectedGate != null &&
                                        selectedGate!.isTwoBitGate)
                                    ? Colors.white
                                    : (isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF8B4513)),
                                width: 2,
                              ),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(isSelected ? 4 : 0),
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

