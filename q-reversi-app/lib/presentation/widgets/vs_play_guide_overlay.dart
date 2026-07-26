import 'package:flutter/material.dart';

/// VS初回ガイド用オーバーレイ（チャレンジと同じ: 暗幕＋吹き出し＋次へ）
class VsPlayGuideOverlay extends StatelessWidget {
  const VsPlayGuideOverlay({
    super.key,
    required this.targetRect,
    required this.message,
    required this.nextLabel,
    required this.onNext,
    this.scale = 1.15,
    this.highlightPadding = 0,
    this.borderWidth = 2,
  });

  final Rect targetRect;
  final String message;
  final String nextLabel;
  final VoidCallback onNext;
  final double scale;
  /// 対象を一回り大きく囲む余白（px）
  final double highlightPadding;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padded = targetRect.inflate(highlightPadding);
    final rawHighlight = Rect.fromCenter(
      center: padded.center,
      width: padded.width * scale,
      height: padded.height * scale,
    );
    // 画面外にはみ出さないようクランプ
    final highlightRect = Rect.fromLTRB(
      rawHighlight.left.clamp(8.0, screenSize.width - 8.0),
      rawHighlight.top.clamp(8.0, screenSize.height - 8.0),
      rawHighlight.right.clamp(8.0, screenSize.width - 8.0),
      rawHighlight.bottom.clamp(8.0, screenSize.height - 8.0),
    );

    final center = highlightRect.center;
    final bubbleWidth =
        (screenSize.width - 24).clamp(200.0, 300.0).toDouble();
    const bubbleHeight = 168.0;
    final left = (center.dx - bubbleWidth / 2)
        .clamp(12.0, screenSize.width - bubbleWidth - 12.0)
        .toDouble();
    var top = (highlightRect.bottom + 12.0 + bubbleHeight < screenSize.height)
        ? (highlightRect.bottom + 12.0)
        : (highlightRect.top - bubbleHeight - 12.0);
    top = top.clamp(12.0, screenSize.height - bubbleHeight - 12.0);
    final isBubbleAbove = top < highlightRect.top;
    final connectorX =
        (center.dx - left).clamp(14.0, bubbleWidth - 14.0).toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onNext,
            behavior: HitTestBehavior.opaque,
            child: ClipPath(
              clipper: _VsGuideCutoutClipper(
                targetRect: highlightRect,
                borderRadius: 12,
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(color: Colors.black54),
            ),
          ),
        ),
        // 強調は周囲の暗幕を抜いただけ＋白枠（塗り・白グローなし）
        Positioned(
          left: highlightRect.left,
          top: highlightRect.top,
          child: IgnorePointer(
            child: Container(
              width: highlightRect.width,
              height: highlightRect.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: borderWidth),
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: bubbleWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isBubbleAbove)
                    Padding(
                      padding: EdgeInsets.only(left: connectorX - 6),
                      child: const Icon(
                        Icons.arrow_drop_up,
                        color: Color(0xFF2A3158),
                        size: 16,
                      ),
                    ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A3158),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: onNext,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  nextLabel,
                                  style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isBubbleAbove)
                    Padding(
                      padding: EdgeInsets.only(left: connectorX - 6),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF2A3158),
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VsGuideCutoutClipper extends CustomClipper<Path> {
  const _VsGuideCutoutClipper({
    required this.targetRect,
    required this.borderRadius,
  });

  final Rect targetRect;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  bool shouldReclip(covariant _VsGuideCutoutClipper oldClipper) {
    return oldClipper.targetRect != targetRect ||
        oldClipper.borderRadius != borderRadius;
  }
}
