import 'package:flutter/material.dart';
import '../../../domain/entities/piece_type.dart';

/// 図解ウィジェット
class TutorialDiagramWidget extends StatelessWidget {
  final Map<String, dynamic>? data;

  const TutorialDiagramWidget({
    super.key,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final diagramType = data?['type'] as String?;

    switch (diagramType) {
      case 'entanglement':
        return _buildEntanglementDiagram();
      case 'cnot_patterns':
        return _buildCnotPatternsDiagram();
      case 'measurement':
        return _buildMeasurementDiagram();
      case 'gray_piece_equals_video':
        return _buildGrayPieceEqualsVideo();
      case 'piece_kinds':
        return _buildPieceKindsDiagram();
      default:
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: const Center(
            child: Text(
              '図解',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
    }
  }

  Widget _buildEntanglementDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEntangledPiece(true),
              const SizedBox(width: 32),
              Container(
                width: 2,
                height: 40,
                color: const Color(0xFFEC4899),
              ),
              const SizedBox(width: 32),
              _buildEntangledPiece(false),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'エンタングル状態',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntangledPiece(bool isBlackWhite) {
    return Container(
      width: 50,
      height: 50,
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
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFEC4899),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isBlackWhite ? Colors.black : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isBlackWhite ? Colors.white : Colors.black,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(17.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCnotPatternsDiagram() {
    final mode = data?['mode'] as String? ?? 'normal';
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mode == 'normal' ? '通常パターン' : 'VSモード白プレイヤー',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'パターン一覧（詳細は実装中）',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementDiagram() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 画面幅と高さに応じてサイズを調整
        final availableWidth = constraints.maxWidth - 32; // padding分を引く
        final availableHeight = constraints.maxHeight; // paddingはContainerで管理
        
        // 幅に基づくサイズ計算
        final baseSizeByWidth = (availableWidth / 5).clamp(30.0, 80.0);
        
        // 高さに基づくサイズ計算
        // 1つのフローの実際の高さ = pieceSize * 2.25（矢印の高さが最大）
        // 2つのフロー + 隙間（最小限）が収まるように調整
        const minGap = 4.0; // 最小の隙間
        // availableHeight >= pieceSize * 2.25 * 2 + minGap
        // pieceSize <= (availableHeight - minGap) / 4.5
        final baseSizeByHeight = ((availableHeight - minGap) / 4.5).clamp(20.0, 80.0);
        
        // 幅と高さの両方を考慮して、小さい方を採用
        final baseSize = (baseSizeByWidth < baseSizeByHeight ? baseSizeByWidth : baseSizeByHeight);
        
        final pieceSize = baseSize;
        final arrowSize = baseSize * 0.4;
        final imageSize = baseSize;
        final spacing = baseSize * 0.2;
        
        return Container(
          padding: EdgeInsets.zero, // paddingを完全に削除
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // パターン1: グレー → 測定 → 白
              _buildMeasurementFlow(
                imagePath: 'assets/mesurement.png',
                resultPieceType: PieceType.white,
                pieceSize: pieceSize,
                arrowSize: arrowSize,
                imageSize: imageSize,
                spacing: spacing,
              ),
              
              const SizedBox(height: minGap), // 最小限の隙間のみ
              
              // パターン2: グレー → 測定 → 黒
              _buildMeasurementFlow(
                imagePath: 'assets/mesurement.png',
                resultPieceType: PieceType.black,
                pieceSize: pieceSize,
                arrowSize: arrowSize,
                imageSize: imageSize,
                spacing: spacing,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementFlow({
    required String imagePath,
    required PieceType resultPieceType,
    required double pieceSize,
    required double arrowSize,
    required double imageSize,
    required double spacing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // グレー駒（プレーンなグレー）
        _buildPlainGrayPiece(size: pieceSize),
        
        // 実線矢印画像（グレー駒→測定画像）
        SizedBox(
          width: spacing * 2.5 * 1.5,
          height: pieceSize * 1.5 * 1.5,
          child: Image.asset(
            'assets/whiteLine.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('画像読み込みエラー: assets/whiteLine.png');
              return Container(
                width: spacing * 2.5 * 1.5,
                height: pieceSize * 1.5 * 1.5,
                color: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white70,
                ),
              );
            },
          ),
        ),
        
        // 測定画像（「測定」テキスト付き）
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('画像読み込みエラー: $imagePath');
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
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: imageSize * 0.4,
                    ),
                  );
                },
              ),
              // 「測定」テキストを画像の上に重ねて表示
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '測定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: imageSize * 0.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 点線双方向矢印画像（測定画像↔白/黒駒）+ "50%"テキスト
        SizedBox(
          width: spacing * 2.5 * 1.5,
          height: pieceSize * 1.5 * 1.5,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // テキストがはみ出しても表示されるように
            children: [
              // 点線双方向矢印画像（背景）
              Image.asset(
                'assets/whiteDotArrow.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('画像読み込みエラー: assets/whiteDotArrow.png');
                  return Container(
                    width: spacing * 2.5 * 1.5,
                    height: pieceSize * 1.5 * 1.5,
                    color: Colors.white.withOpacity(0.1),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
              // "50%"テキストを画像の上端に重ねて表示
              // BoxFit.containの場合、画像は中央に配置されるため、
              // 画像の上端に合わせるために、少し下に配置
              Positioned(
                top: pieceSize * 1.5 * 1.5 * 0.28, // 画像の上端に合わせるための調整
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '50%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: pieceSize * 0.3, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 結果の駒（白または黒）
        _buildResultPiece(
          pieceType: resultPieceType,
          size: pieceSize,
        ),
      ],
    );
  }

  Widget _buildPlainGrayPiece({required double size}) {
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
            color: Colors.grey.shade600, // プレーンなグレー
            border: Border.all(
              color: Colors.grey.shade700,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultPiece({
    required PieceType pieceType,
    required double size,
  }) {
    Color pieceColor;
    Color borderColor;
    
    if (pieceType == PieceType.white) {
      pieceColor = Colors.white;
      borderColor = Colors.grey.shade700;
    } else {
      pieceColor = Colors.black;
      borderColor = Colors.grey.shade700;
    }
    
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
            color: pieceColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrayPieceEqualsVideo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 画面幅に応じてサイズを調整
        final availableWidth = constraints.maxWidth - 32; // padding分を引く
        final baseSize = (availableWidth / 4).clamp(60.0, 120.0); // 4要素（駒、=、動画、スペース）で分割
        
        final pieceSize = baseSize;
        final videoSize = baseSize; // 動画のサイズをグレー駒と同じサイズに
        final spacing = baseSize * 0.2;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // グレー駒
              _buildPlainGrayPiece(size: pieceSize),
              
              SizedBox(width: spacing),
              
              // "="記号
              Text(
                '=',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: pieceSize * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(width: spacing),
              
              // coinTossのGIF（mp4だと初期化に時間がかかるため）
              SizedBox(
                width: videoSize,
                height: videoSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/coinToss.gif',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieceKindsDiagram() {
    final variant = data?['variant'] as String?;
    final braKet = variant == 'bra_ket';
    return LayoutBuilder(
      builder: (context, constraints) {
        // 左右 padding 8×2
        final innerW = (constraints.maxWidth - 16).clamp(0.0, double.infinity);
        final horizontalGap = braKet
            ? (innerW * 0.03).clamp(6.0, 16.0)
            : (constraints.maxWidth * 0.04).clamp(12.0, 28.0);
        final verticalGap = (constraints.maxWidth * 0.05).clamp(16.0, 28.0);
        final labelFontSize = braKet
            ? (innerW < 320 ? 11.5 : (innerW < 380 ? 13.0 : 14.5))
            : 16.0;
        final pieceSize = braKet
            ? (((innerW - horizontalGap) / 2 * 0.42) * 2.0).clamp(72.0, 104.0)
            : 52.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPieceKindsPair(
                leftLabel: braKet ? '白 |\u20600\u2060⟩：' : '白：',
                leftType: PieceType.white,
                rightLabel: braKet ? '黒 |\u20601\u2060⟩：' : '黒：',
                rightType: PieceType.black,
                horizontalGap: horizontalGap,
                labelFontSize: labelFontSize,
                pieceSize: pieceSize,
              ),
              SizedBox(height: verticalGap),
              _buildPieceKindsPair(
                leftLabel: braKet ? 'グレープラス |\u2060+\u2060⟩：' : 'グレープラス：',
                leftType: PieceType.grayPlus,
                rightLabel: braKet ? 'グレーマイナス |\u2060-\u2060⟩：' : 'グレーマイナス：',
                rightType: PieceType.grayMinus,
                horizontalGap: horizontalGap,
                labelFontSize: labelFontSize,
                pieceSize: pieceSize,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieceKindsPair({
    required String leftLabel,
    required PieceType leftType,
    required String rightLabel,
    required PieceType rightType,
    required double horizontalGap,
    double labelFontSize = 16,
    double pieceSize = 52,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPieceKindCell(
            leftLabel,
            leftType,
            labelFontSize: labelFontSize,
            pieceSize: pieceSize,
          ),
        ),
        SizedBox(width: horizontalGap),
        Expanded(
          child: _buildPieceKindCell(
            rightLabel,
            rightType,
            labelFontSize: labelFontSize,
            pieceSize: pieceSize,
          ),
        ),
      ],
    );
  }

  Widget _buildPieceKindCell(
    String label,
    PieceType type, {
    double labelFontSize = 16,
    double pieceSize = 52,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              softWrap: true,
            ),
          ),
          const SizedBox(height: 8),
          _buildLabeledPiece(type, pieceSize),
        ],
      ),
    );
  }

  Widget _buildLabeledPiece(PieceType type, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2E7D32),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pieceColorFor(type),
            border: Border.all(
              color: Colors.grey.shade700,
              width: 1,
            ),
          ),
          child: _pieceMarkFor(type, size),
        ),
      ),
    );
  }

  Color _pieceColorFor(PieceType type) {
    switch (type) {
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

  Widget? _pieceMarkFor(PieceType type, double size) {
    if (type == PieceType.grayPlus) {
      return Center(
        child: Text(
          '+',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (type == PieceType.grayMinus) {
      return Center(
        child: Text(
          '−',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }
    return null;
  }
}

