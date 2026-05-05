import 'dart:math' as math;
import 'package:flutter/material.dart';

/// スタディ用グラフカード（2マス画面と共通）
class StudyQuantumGraphCard extends StatelessWidget {
  const StudyQuantumGraphCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121733),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEAF0FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// スタディ用棒グラフ（2マス画面と共通）
class StudyQuantumStateBarChart extends StatelessWidget {
  const StudyQuantumStateBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.barColor,
    required this.zeroLineColor,
    required this.valueFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final double minY;
  final double maxY;
  final Color barColor;
  final Color zeroLineColor;
  final String Function(double) valueFormatter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _StudyQuantumStateBarChartPainter(
            values: values,
            labels: labels,
            minY: minY,
            maxY: maxY,
            barColor: barColor,
            zeroLineColor: zeroLineColor,
            valueFormatter: valueFormatter,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _StudyQuantumStateBarChartPainter extends CustomPainter {
  _StudyQuantumStateBarChartPainter({
    required this.values,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.barColor,
    required this.zeroLineColor,
    required this.valueFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final double minY;
  final double maxY;
  final Color barColor;
  final Color zeroLineColor;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const rightPad = 10.0;
    const topPad = 10.0;
    const bottomPad = 24.0;

    final chartRect = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (chartRect.width <= 0 || chartRect.height <= 0 || values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(chartRect, framePaint);

    _drawHorizontalGrid(canvas, chartRect, gridPaint);
    _drawZeroLine(canvas, chartRect);
    _drawBars(canvas, chartRect);
    _drawYAxisLabels(canvas, chartRect);
    _drawXAxisLabels(canvas, chartRect);
  }

  void _drawHorizontalGrid(Canvas canvas, Rect rect, Paint gridPaint) {
    const divisions = 4;
    for (int i = 1; i < divisions; i++) {
      final y = rect.top + (rect.height * i / divisions);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawZeroLine(Canvas canvas, Rect rect) {
    if (minY > 0 || maxY < 0) return;
    final y = _mapY(0, rect);
    final p = Paint()
      ..color = zeroLineColor
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), p);
  }

  void _drawBars(Canvas canvas, Rect rect) {
    final count = values.length;
    final section = rect.width / count;
    final barWidth = section * 0.52;
    final radius = Radius.circular(math.min(4, barWidth * 0.2));

    for (int i = 0; i < count; i++) {
      final v = values[i].clamp(minY, maxY);
      final xCenter = rect.left + section * (i + 0.5);
      final xLeft = xCenter - barWidth / 2;
      final xRight = xCenter + barWidth / 2;
      final y0 = _mapY(0.0.clamp(minY, maxY).toDouble(), rect);
      final yV = _mapY(v.toDouble(), rect);
      final top = math.min(y0, yV);
      final bottom = math.max(y0, yV);
      final barRect = Rect.fromLTRB(xLeft, top, xRight, bottom);

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          barColor.withValues(alpha: 0.72),
          barColor,
        ],
      );

      final p = Paint()
        ..shader = gradient.createShader(barRect)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, radius), p);

      _drawText(
        canvas,
        valueFormatter(values[i]),
        Offset(xCenter, top - 10),
        const TextStyle(
          color: Color(0xFFEAF0FF),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  void _drawYAxisLabels(Canvas canvas, Rect rect) {
    _drawText(
      canvas,
      maxY.toStringAsFixed(1),
      Offset(rect.left - 20, rect.top),
      const TextStyle(color: Color(0xFFC8D0EA), fontSize: 10),
      alignCenter: true,
    );
    _drawText(
      canvas,
      minY.toStringAsFixed(1),
      Offset(rect.left - 20, rect.bottom),
      const TextStyle(color: Color(0xFFC8D0EA), fontSize: 10),
      alignCenter: true,
    );
    if (minY <= 0 && maxY >= 0) {
      _drawText(
        canvas,
        '0.0',
        Offset(rect.left - 20, _mapY(0, rect)),
        const TextStyle(color: Color(0xFFC8D0EA), fontSize: 10),
        alignCenter: true,
      );
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect rect) {
    final count = labels.length;
    final section = rect.width / count;
    for (int i = 0; i < count; i++) {
      final x = rect.left + section * (i + 0.5);
      _drawText(
        canvas,
        labels[i],
        Offset(x, rect.bottom + 12),
        const TextStyle(
          color: Color(0xFFDDE4FF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  double _mapY(double value, Rect rect) {
    final t = (value - minY) / (maxY - minY);
    return rect.bottom - t * rect.height;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool alignCenter = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      alignCenter ? anchor.dx - painter.width / 2 : anchor.dx,
      anchor.dy - painter.height / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StudyQuantumStateBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.barColor != barColor ||
        oldDelegate.zeroLineColor != zeroLineColor;
  }
}
