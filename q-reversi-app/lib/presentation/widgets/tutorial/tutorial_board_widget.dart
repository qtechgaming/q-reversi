import 'package:flutter/material.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/piece.dart';
import '../../../domain/entities/piece_type.dart';
import '../../../domain/entities/position.dart';
import '../piece_widget.dart';

/// チュートリアル用盤面ウィジェット（フリーランモードと同じ見た目、盤面のみ表示）
class TutorialBoardWidget extends StatelessWidget {
  final Map<String, dynamic>? data;

  const TutorialBoardWidget({
    super.key,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    // dataパラメータで特別な表示モードをチェック
    final displayMode = data?['mode'] as String?;
    
    if (displayMode == 'mini_board_with_image') {
      return _buildMiniBoardWithImage(context);
    }
    
    // デフォルトの盤面を可変サイズで表示（1画面に収まるように）
    return LayoutBuilder(
      builder: (context, constraints) {
        // デフォルトの盤面を作成（様々な駒を配置）
        final board = _createDemoBoard();
        
        // 画面サイズに応じてセルサイズを調整
        // マージン(2px * 2)とボーダー(3px * 2)を考慮
        const padding = 16.0 * 2; // 左右のpadding
        const margin = 2.0 * 2; // 各セルの左右マージン
        const border = 3.0 * 2; // 各セルの左右ボーダー
        final availableWidth = constraints.maxWidth - padding;
        final availableHeight = constraints.maxHeight - padding;
        
        // 幅に基づくセルサイズ
        final cellSizeByWidth = ((availableWidth - (margin + border) * 8) / 8).floor().toDouble();
        
        // 高さに基づくセルサイズ（8行分のマージンとボーダーを考慮）
        final cellSizeByHeight = ((availableHeight - (margin + border) * 8) / 8).floor().toDouble();
        
        // 幅と高さの両方を考慮して、小さい方を採用
        final cellSize = (cellSizeByWidth < cellSizeByHeight ? cellSizeByWidth : cellSizeByHeight)
            .clamp(20.0, 45.0);

        // 盤面グリッドのみを表示（行/列選択ボタンなし）
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 盤面グリッド
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board.rows, (row) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(board.cols, (col) {
                        final piece = board.getPiece(row, col);
                        
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // 緑色の背景
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF4CAF50), // 緑色の枠線
                              width: 3,
                            ),
                          ),
                          child: piece != null
                              ? Center(
                                  child: PieceWidget(
                                    piece: piece,
                                    size: cellSize - 8,
                                  ),
                                )
                              : null,
                        );
                      }),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBoardWithImage(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能な幅を計算（padding分を引く）
        final availableWidth = constraints.maxWidth - 32; // 左右のpadding 16 * 2
        const spacing = 16.0;
        
        // 画面幅に応じてサイズを調整
        // 最小サイズを確保しつつ、画面幅に収まるようにする
        const minImageSize = 150.0;
        const maxImageSize = 300.0;
        
        // 画像と盤面の合計幅が利用可能な幅に収まるように調整
        const totalNeededWidth = minImageSize * 2 + spacing; // 画像 + 盤面 + スペース
        double imageSize;
        if (totalNeededWidth <= availableWidth) {
          // 余裕がある場合は、画面幅の40%程度を使用
          imageSize = (availableWidth * 0.4).clamp(minImageSize, maxImageSize);
        } else {
          // 画面幅が足りない場合は、利用可能な幅に合わせて縮小
          imageSize = ((availableWidth - spacing) / 2).clamp(100.0, maxImageSize);
        }
        
        // 盤面サイズは画像サイズの0.9倍（少し小さく）
        final boardSize = imageSize * 0.9;
        
        // ミニ盤面のセルサイズを計算（3列、3行）
        const margin = 2.0 * 2;
        const border = 3.0 * 2;
        const boardPadding = 8.0 * 2; // 盤面の左右パディング
        final availableBoardWidth = boardSize - boardPadding;
        final cellSize = ((availableBoardWidth - (margin + border) * 3) / 3).floor().toDouble().clamp(20.0, 50.0);
        
        // ミニ盤面を作成（3x3）
        final miniBoard = _createMiniBoard();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, containerConstraints) {
              // コンテナの幅に収まるように調整
              final totalWidth = imageSize + spacing + boardSize;
              final needsScroll = totalWidth > containerConstraints.maxWidth;
              
              final content = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // QC_img.png（左側）
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '量子コンピュータ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: Image.asset(
                          'assets/QC_img.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('画像読み込みエラー: assets/QC_img.png');
                            debugPrint('エラー: $error');
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '画像を読み込めません\nassets/QC_img.png',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: spacing),
                  // ミニ盤面（3x3）（右側）- 少し小さく
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Qリバーシ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(miniBoard.rows, (row) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(miniBoard.cols, (col) {
                                  final piece = miniBoard.getPiece(row, col);
                                  
                                  return Container(
                                    width: cellSize,
                                    height: cellSize,
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50), // 緑色の背景
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFF2E7D32), // 濃い緑色の枠線
                                        width: 3,
                                      ),
                                    ),
                                    child: piece != null
                                        ? Center(
                                            child: _buildMiniPiece(piece, cellSize - 8),
                                          )
                                        : null,
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              
              // 画面幅に収まらない場合はスクロール可能にする
              if (needsScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                );
              } else {
                return Center(child: content);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMiniPiece(Piece piece, double size) {
    Color pieceColor;
    switch (piece.type) {
      case PieceType.white:
        pieceColor = Colors.white;
        break;
      case PieceType.black:
        pieceColor = Colors.black;
        break;
      case PieceType.grayPlus:
      case PieceType.grayMinus:
        pieceColor = Colors.grey.shade600; // グレー（プラス/マイナス記号なし）
        break;
      default:
        pieceColor = Colors.grey.shade600;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pieceColor,
        border: Border.all(
          color: Colors.grey.shade700,
          width: 1,
        ),
      ),
    );
  }

  Board _createMiniBoard() {
    // 3x3の盤面を作成（3行3列）
    final board = Board(
      pieces: List.generate(3, (r) => List.generate(3, (c) => null)),
      rows: 3,
      cols: 3,
    );
    var newBoard = board;
    int pieceIdCounter = 0;
    
    // 指定された配置で駒を配置
    // 行0: 白、黒、グレー
    newBoard = newBoard.setPiece(0, 0, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.white,
      position: const Position(0, 0),
    ));
    newBoard = newBoard.setPiece(0, 1, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.black,
      position: const Position(0, 1),
    ));
    newBoard = newBoard.setPiece(0, 2, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.grayPlus, // プラス/マイナス記号は表示しない
      position: const Position(0, 2),
    ));
    
    // 行1: グレー、グレー、黒
    newBoard = newBoard.setPiece(1, 0, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.grayPlus,
      position: const Position(1, 0),
    ));
    newBoard = newBoard.setPiece(1, 1, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.grayPlus,
      position: const Position(1, 1),
    ));
    newBoard = newBoard.setPiece(1, 2, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.black,
      position: const Position(1, 2),
    ));
    
    // 行2: グレー、白、黒
    newBoard = newBoard.setPiece(2, 0, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.grayPlus,
      position: const Position(2, 0),
    ));
    newBoard = newBoard.setPiece(2, 1, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.white,
      position: const Position(2, 1),
    ));
    newBoard = newBoard.setPiece(2, 2, Piece(
      id: 'piece_${pieceIdCounter++}',
      type: PieceType.black,
      position: const Position(2, 2),
    ));
    
    return newBoard;
  }

  Board _createDemoBoard() {
    final board = Board.create8x8();
    final pieces = <Piece>[];
    
    // 様々な駒を配置（デモ用）
    pieces.add(const Piece(
      id: '1',
      type: PieceType.white,
      position: Position(2, 2),
    ));
    pieces.add(const Piece(
      id: '2',
      type: PieceType.black,
      position: Position(2, 3),
    ));
    pieces.add(const Piece(
      id: '3',
      type: PieceType.grayPlus,
      position: Position(3, 2),
    ));
    pieces.add(const Piece(
      id: '4',
      type: PieceType.grayMinus,
      position: Position(3, 3),
    ));
    pieces.add(const Piece(
      id: '5',
      type: PieceType.blackWhite,
      position: Position(4, 4),
    ));
    pieces.add(const Piece(
      id: '6',
      type: PieceType.whiteBlack,
      position: Position(4, 5),
    ));
    
    var newBoard = board;
    for (final piece in pieces) {
      newBoard = newBoard.setPiece(
        piece.position.row,
        piece.position.col,
        piece,
      );
    }
    
    return newBoard;
  }
}

