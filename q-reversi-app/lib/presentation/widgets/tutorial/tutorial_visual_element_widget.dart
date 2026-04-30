import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../domain/entities/tutorial_content.dart';
import 'tutorial_board_widget.dart';
import 'tutorial_gate_transformation_widget.dart';
import 'tutorial_comparison_diagram_widget.dart';
import 'tutorial_gate_list_widget.dart';
import 'tutorial_diagram_widget.dart';
import 'tutorial_animation_widget.dart';

/// チュートリアル視覚要素ウィジェット
class TutorialVisualElementWidget extends StatelessWidget {
  final TutorialVisualElement visualElement;

  const TutorialVisualElementWidget({
    super.key,
    required this.visualElement,
  });

  @override
  Widget build(BuildContext context) {
    switch (visualElement.type) {
      case VisualElementType.board:
        return TutorialBoardWidget(data: visualElement.data);
      
      case VisualElementType.transformation:
        return TutorialGateTransformationWidget(data: visualElement.data);
      
      case VisualElementType.comparison:
        return TutorialComparisonDiagramWidget(data: visualElement.data);
      
      case VisualElementType.gateList:
        return const TutorialGateListWidget();
      
      case VisualElementType.diagram:
        return TutorialDiagramWidget(data: visualElement.data);
      
      case VisualElementType.animation:
        return TutorialAnimationWidget(data: visualElement.data);
      
      case VisualElementType.video:
        return _buildVideoWidget(visualElement.data);
      
      case VisualElementType.image:
        final imagePath = visualElement.data?['path'] as String?;
        if (imagePath == null) {
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
                '画像が見つかりません',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        // 画像パスを正規化（assets/で始まる場合はそのまま、そうでない場合は追加）
        final normalizedPath = imagePath.startsWith('assets/') 
            ? imagePath 
            : 'assets/$imagePath';
        
        // 盤面と同じサイズを計算（盤面の最大サイズに合わせる）
        final screenWidth = MediaQuery.of(context).size.width;
        const padding = 16.0 * 2; // 左右のpadding
        const margin = 2.0 * 2; // 各セルの左右マージン
        const border = 3.0 * 2; // 各セルの左右ボーダー
        final availableWidth = screenWidth - padding;
        final cellSize = ((availableWidth - (margin + border) * 8) / 8).floor().toDouble().clamp(25.0, 45.0);
        // 盤面全体のサイズ = セルサイズ * 8 + マージン * 8 + ボーダー * 8
        final boardSize = cellSize * 8 + (margin + border) * 8;
        
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: boardSize,
            maxHeight: boardSize,
          ),
          child: Image.asset(
            normalizedPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('画像読み込みエラー: $normalizedPath');
              debugPrint('エラー: $error');
              debugPrint('スタックトレース: $stackTrace');
              
              return Container(
                height: boardSize,
                width: boardSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '画像を読み込めません\n$normalizedPath\n\nエラー: ${error.toString()}',
                        style: const TextStyle(
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
        );
    }
  }

  Widget _buildVideoWidget(Map<String, dynamic>? data) {
    final videoPath = data?['path'] as String?;
    if (videoPath == null) {
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
            '動画パスが指定されていません',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    final normalizedPath = videoPath.startsWith('assets/')
        ? videoPath
        : 'assets/$videoPath';
    
    return _VideoPlayerWidget(videoPath: normalizedPath);
  }
}

/// 動画プレイヤーウィジェット
class _VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerWidget({
    required this.videoPath,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller.initialize();
      _controller.setLooping(true); // ループ再生を有効化
      _controller.play(); // 自動再生
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('動画読み込みエラー: ${widget.videoPath}');
      debugPrint('エラー: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                '動画を読み込めません\n${widget.videoPath}\n\nエラー: $_errorMessage',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 動画のアスペクト比を取得
        final aspectRatio = _controller.value.aspectRatio;
        final maxHeight = constraints.maxHeight.clamp(200.0, 400.0);
        final maxWidth = constraints.maxWidth;
        
        // アスペクト比を考慮してサイズを計算
        double videoWidth;
        double videoHeight;
        
        if (maxWidth / aspectRatio <= maxHeight) {
          // 幅に合わせる
          videoWidth = maxWidth;
          videoHeight = maxWidth / aspectRatio;
        } else {
          // 高さに合わせる
          videoHeight = maxHeight;
          videoWidth = maxHeight * aspectRatio;
        }
        
        // 縦横1/2のサイズにする
        videoWidth = videoWidth * 0.5;
        videoHeight = videoHeight * 0.5;
        
        return Center(
          child: SizedBox(
            width: videoWidth,
            height: videoHeight,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        );
      },
    );
  }
}

