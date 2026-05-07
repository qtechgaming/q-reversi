import 'dart:math' as math;
import 'package:flutter/material.dart';

class StudyTextTutorialStep {
  const StudyTextTutorialStep({
    required this.message,
    this.title,
    this.targetKey,
    this.additionalHighlightKeys = const [],
    this.bubbleBottomAnchorKey,
    this.showNextButton = true,
    this.nextLabel = '次へ',
    this.dimBackground = true,
    this.highlightExpandX = 0,
    this.highlightExpandY = 0,
  });

  final String message;
  final String? title;
  final GlobalKey? targetKey;
  final List<GlobalKey> additionalHighlightKeys;
  final GlobalKey? bubbleBottomAnchorKey;
  final bool showNextButton;
  final String nextLabel;
  final bool dimBackground;
  final double highlightExpandX;
  final double highlightExpandY;
}

class StudyTextTutorialOverlay extends StatefulWidget {
  const StudyTextTutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onClose,
  });

  final StudyTextTutorialStep step;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  State<StudyTextTutorialOverlay> createState() => _StudyTextTutorialOverlayState();
}

class _StudyTextTutorialOverlayState extends State<StudyTextTutorialOverlay> {
  static const String _diffCircuitToken = '[Diff = H→X→CCZ→X→H]';
  final GlobalKey _bubbleMeasureKey = GlobalKey();
  double _measuredBubbleHeight = 220;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubbleHeight());
  }

  @override
  void didUpdateWidget(covariant StudyTextTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubbleHeight());
    }
  }

  void _measureBubbleHeight() {
    if (!mounted) return;
    final render = _bubbleMeasureKey.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final h = render.size.height;
    if ((h - _measuredBubbleHeight).abs() > 0.5) {
      setState(() {
        _measuredBubbleHeight = h;
      });
    }
  }

  Rect? _targetRect(BuildContext context) {
    final key = widget.step.targetKey;
    if (key == null) return null;
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    final overlayBox = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        overlayBox is! RenderBox) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero, ancestor: overlayBox);
    return offset & renderObject.size;
  }

  List<Rect> _additionalRects(BuildContext context) {
    final rects = <Rect>[];
    for (final key in widget.step.additionalHighlightKeys) {
      final rect = _rectForKey(context, key);
      if (rect != null) rects.add(rect);
    }
    return rects;
  }

  Rect? _rectForKey(BuildContext context, GlobalKey? key) {
    if (key == null) return null;
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    final overlayBox = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        overlayBox is! RenderBox) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero, ancestor: overlayBox);
    return offset & renderObject.size;
  }

  TextSpan _buildMessageSpan(String message) {
    const normal = TextStyle(
      color: Colors.white,
      fontSize: 15,
      height: 1.5,
    );
    const note = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      height: 1.4,
    );

    final lines = message.split('\n');
    final spans = <InlineSpan>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isNote = line.trimLeft().startsWith('※');
      spans.add(TextSpan(text: line, style: isNote ? note : normal));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n', style: normal));
      }
    }
    return TextSpan(children: spans);
  }

  String _messageWithoutSpecialLines(String message) {
    final lines = message
        .split('\n')
        .where((line) => line.trim() != _diffCircuitToken)
        .toList();
    return lines.join('\n');
  }

  Widget _buildDiffCircuitInline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2142),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 440,
          height: 86,
          child: CustomPaint(
            painter: _DiffCircuitPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      key: _bubbleMeasureKey,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2A3158),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.step.title != null) ...[
            Text(
              widget.step.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
          ],
          RichText(
            text: _buildMessageSpan(_messageWithoutSpecialLines(widget.step.message)),
          ),
          if (widget.step.message.contains(_diffCircuitToken)) ...[
            const SizedBox(height: 8),
            _buildDiffCircuitInline(),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onClose,
                child: const Text(
                  '閉じる',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              if (widget.step.showNextButton)
                InkWell(
                  onTap: widget.onNext,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      widget.step.nextLabel,
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect(context);
    final additionalRects = _additionalRects(context);
    final screen = MediaQuery.of(context).size;
    final bubbleWidth = (screen.width - 24).clamp(260.0, 860.0).toDouble();

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (widget.step.dimBackground)
              Positioned.fill(
                child: rect == null && additionalRects.isEmpty
                    ? Container(color: Colors.black.withValues(alpha: 0.4))
                    : ClipPath(
                        clipper: _HighlightCutoutClipper(
                          targetRects: [
                            if (rect != null)
                              Rect.fromLTWH(
                                rect.left + 2 - widget.step.highlightExpandX,
                                rect.top + 2 - widget.step.highlightExpandY,
                                rect.width - 4 + widget.step.highlightExpandX * 2,
                                rect.height - 4 + widget.step.highlightExpandY * 2,
                              ),
                            ...additionalRects.map(
                              (r) => Rect.fromLTWH(
                                r.left + 2 - widget.step.highlightExpandX,
                                r.top + 2 - widget.step.highlightExpandY,
                                r.width - 4 + widget.step.highlightExpandX * 2,
                                r.height - 4 + widget.step.highlightExpandY * 2,
                              ),
                            ),
                          ],
                          borderRadius: 10,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            if (rect != null)
              Positioned(
                left: rect.left + 2 - widget.step.highlightExpandX,
                top: rect.top + 2 - widget.step.highlightExpandY,
                width: rect.width - 4 + widget.step.highlightExpandX * 2,
                height: rect.height - 4 + widget.step.highlightExpandY * 2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xCCFFFFFF),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ...additionalRects.map(
              (r) => Positioned(
                left: r.left + 2 - widget.step.highlightExpandX,
                top: r.top + 2 - widget.step.highlightExpandY,
                width: r.width - 4 + widget.step.highlightExpandX * 2,
                height: r.height - 4 + widget.step.highlightExpandY * 2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xCCFFFFFF),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (rect == null)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: bubbleWidth,
                    minWidth: bubbleWidth,
                    maxHeight: screen.height * 0.7,
                  ),
                  child: SingleChildScrollView(
                    child: _buildBubble(),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final center = rect.center;
                  final left = (center.dx - bubbleWidth / 2)
                      .clamp(12.0, screen.width - bubbleWidth - 12.0)
                      .toDouble();
                  const gap = 12.0;
                  const outerMargin = 12.0;
                  final availableBelow =
                      (screen.height - (rect.bottom + gap) - outerMargin)
                          .clamp(0.0, screen.height)
                          .toDouble();
                  final availableAbove = (rect.top - gap - outerMargin)
                      .clamp(0.0, screen.height)
                      .toDouble();
                  final showBelow = availableBelow >= availableAbove;
                  final rawBubbleMaxHeight = (showBelow ? availableBelow : availableAbove)
                      .clamp(120.0, screen.height - outerMargin * 2)
                      .toDouble();
                  final bubbleMaxHeight =
                      rawBubbleMaxHeight.clamp(120.0, screen.height * 0.42).toDouble();
                  final effectiveBubbleHeight =
                      _measuredBubbleHeight.clamp(120.0, bubbleMaxHeight).toDouble();
                  final top = showBelow
                      ? (rect.bottom + gap).clamp(
                          outerMargin,
                          screen.height - bubbleMaxHeight - outerMargin,
                        )
                      : (rect.top - gap - effectiveBubbleHeight).clamp(
                          outerMargin,
                          screen.height - bubbleMaxHeight - outerMargin,
                        );
                  final bottomAnchorRect = _rectForKey(
                    context,
                    widget.step.bubbleBottomAnchorKey,
                  );
                  var adjustedTop = top.toDouble();
                  if (bottomAnchorRect != null) {
                    final desiredTop = bottomAnchorRect.top - effectiveBubbleHeight - 8.0;
                    adjustedTop = math.min(adjustedTop, desiredTop).clamp(
                      outerMargin,
                      screen.height - bubbleMaxHeight - outerMargin,
                    );
                  }
                  return Positioned(
                    left: left,
                    top: adjustedTop,
                    child: SizedBox(
                      width: bubbleWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: bubbleMaxHeight),
                            child: SingleChildScrollView(
                              child: _buildBubble(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightCutoutClipper extends CustomClipper<Path> {
  const _HighlightCutoutClipper({
    required this.targetRects,
    required this.borderRadius,
  });

  final List<Rect> targetRects;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final rect in targetRects) {
      path.addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(borderRadius),
        ),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _HighlightCutoutClipper oldClipper) {
    if (oldClipper.borderRadius != borderRadius ||
        oldClipper.targetRects.length != targetRects.length) {
      return true;
    }
    for (int i = 0; i < targetRects.length; i++) {
      if (oldClipper.targetRects[i] != targetRects[i]) return true;
    }
    return false;
  }
}

class _DiffCircuitPainter extends CustomPainter {
  static const List<double> _wireYs = [16.0, 38.0, 60.0];

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = const Color(0xFF8A93B0)
      ..strokeWidth = 1.6;
    final gateFill = Paint()..color = const Color(0xFF252D48);
    final gateStroke = Paint()
      ..color = const Color(0xFF8EB7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()..color = const Color(0xFFEAF0FF);

    const centers = [132.0, 176.0, 226.0, 276.0, 320.0];
    const equalsGapLeft = 90.0;
    const equalsGapRight = 106.0;
    const diffRight = 76.0; // Diffゲート右端
    final diffRightWireLength = equalsGapLeft - diffRight;
    final rightWireEnd = centers[4] + 15.0 + diffRightWireLength;

    // 3本の量子線（= の位置は欠線、右端は最後のゲートで終了）
    for (final y in _wireYs) {
      canvas.drawLine(Offset(8, y), Offset(equalsGapLeft, y), wirePaint);
      canvas.drawLine(Offset(equalsGapRight, y), Offset(rightWireEnd, y), wirePaint);
    }

    // 左辺: Diff（3線をまたぐ）
    final diffRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 6, 56, 64),
      const Radius.circular(5),
    );
    canvas.drawRRect(diffRect, gateFill);
    canvas.drawRRect(diffRect, gateStroke);
    _drawLabel(canvas, 'Diff', const Offset(48, 38), 12);

    // 等号
    _drawLabel(canvas, '=', const Offset(98, 38), 14);

    // 右辺: H, X, CCZ, X, H（3本線で連なる）
    for (final cx in [centers[0], centers[1], centers[3], centers[4]]) {
      for (final y in _wireYs) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y), width: 30, height: 20),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, gateFill);
        canvas.drawRRect(rect, gateStroke);
      }
    }
    for (final y in _wireYs) {
      _drawLabel(canvas, 'H', Offset(centers[0], y), 10);
      _drawLabel(canvas, 'X', Offset(centers[1], y), 10);
      _drawLabel(canvas, 'X', Offset(centers[3], y), 10);
      _drawLabel(canvas, 'H', Offset(centers[4], y), 10);
    }

    final cczRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centers[2], 38), width: 34, height: 64),
      const Radius.circular(5),
    );
    canvas.drawRRect(cczRect, gateFill);
    canvas.drawRRect(cczRect, gateStroke);
    for (final y in _wireYs) {
      canvas.drawCircle(Offset(centers[2], y), 3.0, dotPaint);
    }
    _drawLabel(canvas, 'CCZ', Offset(centers[2], 78), 10);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DiffCircuitPainter oldDelegate) => false;
}
