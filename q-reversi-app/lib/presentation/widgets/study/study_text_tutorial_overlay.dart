import 'package:flutter/material.dart';

class StudyTextTutorialStep {
  const StudyTextTutorialStep({
    required this.message,
    this.title,
    this.targetKey,
    this.showNextButton = true,
    this.nextLabel = '次へ',
    this.dimBackground = true,
    this.highlightExpandX = 0,
    this.highlightExpandY = 0,
  });

  final String message;
  final String? title;
  final GlobalKey? targetKey;
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
            text: _buildMessageSpan(widget.step.message),
          ),
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
    final screen = MediaQuery.of(context).size;
    final bubbleWidth = (screen.width - 24).clamp(260.0, 860.0).toDouble();

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (widget.step.dimBackground)
              Positioned.fill(
                child: rect == null
                    ? Container(color: Colors.black.withValues(alpha: 0.4))
                    : ClipPath(
                        clipper: _HighlightCutoutClipper(
                          targetRect: Rect.fromLTWH(
                            rect.left + 2 - widget.step.highlightExpandX,
                            rect.top + 2 - widget.step.highlightExpandY,
                            rect.width - 4 + widget.step.highlightExpandX * 2,
                            rect.height - 4 + widget.step.highlightExpandY * 2,
                          ),
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
                  return Positioned(
                    left: left,
                    top: top,
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
    required this.targetRect,
    required this.borderRadius,
  });

  final Rect targetRect;
  final double borderRadius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );
    return path;
  }

  @override
  bool shouldReclip(covariant _HighlightCutoutClipper oldClipper) {
    return oldClipper.targetRect != targetRect ||
        oldClipper.borderRadius != borderRadius;
  }
}
