import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BlochAxis {
  x,
  y,
  z,
  h,
}

/// ブロッホ球（簡易3D投影）
class BlochSphereWidget extends StatelessWidget {
  const BlochSphereWidget({
    super.key,
    required this.startVector,
    required this.endVector,
    required this.progress,
    required this.highlightedAxisLine,
    required this.highlightedAxisLabel,
    required this.yaw,
  });

  final BlochVector startVector;
  final BlochVector endVector;
  final double progress;
  final BlochAxis? highlightedAxisLine;
  final BlochAxis? highlightedAxisLabel;
  final double yaw;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _BlochSpherePainter(
          startVector: startVector,
          endVector: endVector,
          progress: progress,
          highlightedAxisLine: highlightedAxisLine,
          highlightedAxisLabel: highlightedAxisLabel,
          yaw: yaw,
        ),
      ),
    );
  }
}

class _BlochSpherePainter extends CustomPainter {
  _BlochSpherePainter({
    required this.startVector,
    required this.endVector,
    required this.progress,
    required this.highlightedAxisLine,
    required this.highlightedAxisLabel,
    required this.yaw,
  });

  final BlochVector startVector;
  final BlochVector endVector;
  final double progress;
  final BlochAxis? highlightedAxisLine;
  final BlochAxis? highlightedAxisLabel;
  final double yaw;

  static const Color _baseAxisColor = Color(0xFF7A7A7A);
  static const Color _highlightColor = Color(0xFF9C6BFF);
  static const double _cameraDistance = 7.2;
  static const double _pitch = 0.27;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    final spherePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF2B3156),
          Color(0xFF181D36),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, spherePaint);

    _drawSphereGrid(canvas, center, radius);
    _drawAxis3d(
      canvas: canvas,
      center: center,
      radius: radius,
      start: const _Vec3(-1.05, 0, 0),
      end: const _Vec3(1.05, 0, 0),
      paint: _axisPaint(BlochAxis.x),
    );
    _drawAxisLabel(
      canvas: canvas,
      center: center,
      radius: radius,
      point: const _Vec3(1.18, 0, 0),
      label: 'Y',
      highlighted: highlightedAxisLabel == BlochAxis.y,
    );
    _drawAxis3d(
      canvas: canvas,
      center: center,
      radius: radius,
      start: const _Vec3(0, -1.05, 0),
      end: const _Vec3(0, 1.05, 0),
      paint: _axisPaint(BlochAxis.y),
    );
    _drawAxisLabel(
      canvas: canvas,
      center: center,
      radius: radius,
      point: const _Vec3(0, 1.18, 0),
      label: 'Z',
      highlighted: highlightedAxisLabel == BlochAxis.z,
    );
    _drawAxis3d(
      canvas: canvas,
      center: center,
      radius: radius,
      start: const _Vec3(0, 0, -1.05),
      end: const _Vec3(0, 0, 1.05),
      paint: _axisPaint(BlochAxis.z),
    );
    _drawAxisLabel(
      canvas: canvas,
      center: center,
      radius: radius,
      point: const _Vec3(0.16, 0, 1.2),
      label: 'X',
      highlighted: highlightedAxisLabel == BlochAxis.x,
    );
    _drawAxis3d(
      canvas: canvas,
      center: center,
      radius: radius,
      // H軸: |0>（上）と |+>（左手前方向）の中間方向
      start: const _Vec3(0, -0.76, -0.76),
      end: const _Vec3(0, 0.76, 0.76),
      paint: _axisPaint(BlochAxis.h),
    );
    _drawAxisLabel(
      canvas: canvas,
      center: center,
      radius: radius,
      point: const _Vec3(-0.2, 0.84, 0.84),
      label: 'H',
      highlighted: highlightedAxisLabel == BlochAxis.h,
    );

    _drawStateLabels(canvas, center, radius);

    final vector = BlochVector.lerp(startVector, endVector, progress);
    final vectorPaint = Paint()
      ..color = const Color(0xFF6FE8FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final projectedVectorEnd = _project(
      _Vec3(vector.x, vector.y, vector.z),
      center,
      radius,
    );
    canvas.drawLine(center, projectedVectorEnd, vectorPaint);

    final headPaint = Paint()..color = const Color(0xFF6FE8FF);
    canvas.drawCircle(projectedVectorEnd, 6, headPaint);
    canvas.drawCircle(
      center,
      4,
      Paint()..color = const Color(0xFFB0B8CC),
    );
  }

  void _drawSphereGrid(Canvas canvas, Offset center, double radius) {
    final gridRadius = radius;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // 緯線は3本（上・赤道・下）
    for (final lat in [-0.5, 0.0, 0.5]) {
      final path = Path();
      bool started = false;
      for (int i = 0; i <= 72; i++) {
        final t = (i / 72) * math.pi * 2;
        final p = _Vec3(
          math.cos(lat * math.pi / 2) * math.cos(t),
          math.sin(lat * math.pi / 2),
          math.cos(lat * math.pi / 2) * math.sin(t),
        );
        final projected = _project(p, center, gridRadius);
        if (!started) {
          path.moveTo(projected.dx, projected.dy);
          started = true;
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 経線は、軸交点を通る大円を2本（裏側を含めて全周描画）
    // base=0   : x-y 平面の大円
    // base=π/2 : y-z 平面の大円
    for (final base in [0.0, math.pi / 2]) {
      final path = Path();
      bool started = false;
      for (int i = 0; i <= 72; i++) {
        final t = -math.pi + (i / 72) * (math.pi * 2);
        final p = _Vec3(
          math.cos(t) * math.cos(base),
          math.sin(t),
          math.cos(t) * math.sin(base),
        );
        final projected = _project(p, center, gridRadius);
        if (!started) {
          path.moveTo(projected.dx, projected.dy);
          started = true;
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawStateLabels(Canvas canvas, Offset center, double radius) {
    _drawText(
      canvas,
      _project(const _Vec3(-0.18, 1.12, 0), center, radius),
      '|0>',
      const Color(0xFFEAF0FF),
    );
    _drawText(
      canvas,
      _project(const _Vec3(-0.16, -1.16, 0), center, radius),
      '|1>',
      const Color(0xFFEAF0FF),
    );
    // |+> を現在の X ラベル位置方向、|-> をその反対方向へ
    _drawText(
      canvas,
      _project(const _Vec3(0, 0, 1.28), center, radius),
      '|+>',
      const Color(0xFFEAF0FF),
    );
    _drawText(
      canvas,
      _project(const _Vec3(0, 0, -1.28), center, radius),
      '|->',
      const Color(0xFFEAF0FF),
    );
  }

  void _drawAxis3d({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required _Vec3 start,
    required _Vec3 end,
    required Paint paint,
  }) {
    final s = _project(start, center, radius);
    final e = _project(end, center, radius);
    canvas.drawLine(s, e, paint);
  }

  Offset _project(_Vec3 point, Offset center, double radius) {
    final cy = math.cos(yaw);
    final sy = math.sin(yaw);
    final cp = math.cos(_pitch);
    final sp = math.sin(_pitch);

    final x1 = point.x * cy + point.z * sy;
    final z1 = -point.x * sy + point.z * cy;
    final y1 = point.y * cp - z1 * sp;
    final z2 = point.y * sp + z1 * cp;

    final perspective = _cameraDistance / (_cameraDistance - z2);
    return Offset(
      center.dx + x1 * radius * perspective,
      center.dy - y1 * radius * perspective,
    );
  }

  void _drawAxisLabel({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required _Vec3 point,
    required String label,
    required bool highlighted,
  }) {
    final pos = _project(point, center, radius);
    _drawText(
      canvas,
      pos,
      label,
      highlighted ? _highlightColor : const Color(0xFF9EA4B8),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
  }

  void _drawText(
    Canvas canvas,
    Offset center,
    String text,
    Color color, {
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        shadows: const [
          Shadow(
            color: Color(0xAA000000),
            blurRadius: 4,
            offset: Offset(0.8, 0.8),
          ),
        ],
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      center.dx - painter.width / 2,
      center.dy - painter.height / 2,
    );
    painter.paint(canvas, offset);
  }

  Paint _axisPaint(BlochAxis axis) {
    final highlighted = highlightedAxisLine == axis;
    return Paint()
      ..color = highlighted ? _highlightColor : _baseAxisColor
      ..strokeWidth = highlighted ? 2.6 : 1.4
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant _BlochSpherePainter oldDelegate) {
    return oldDelegate.startVector != startVector ||
        oldDelegate.endVector != endVector ||
        oldDelegate.progress != progress ||
        oldDelegate.highlightedAxisLine != highlightedAxisLine ||
        oldDelegate.highlightedAxisLabel != highlightedAxisLabel ||
        oldDelegate.yaw != yaw;
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

class BlochVector {
  const BlochVector({
    required this.x,
    required this.y,
    required this.z,
  });

  final double x;
  final double y;
  final double z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);

  BlochVector normalized() {
    final m = magnitude;
    if (m == 0) {
      return const BlochVector(x: 0, y: 0, z: 0);
    }
    return BlochVector(
      x: x / m,
      y: y / m,
      z: z / m,
    );
  }

  static BlochVector lerp(BlochVector a, BlochVector b, double t) {
    return BlochVector(
      x: a.x + (b.x - a.x) * t,
      y: a.y + (b.y - a.y) * t,
      z: a.z + (b.z - a.z) * t,
    );
  }
}
