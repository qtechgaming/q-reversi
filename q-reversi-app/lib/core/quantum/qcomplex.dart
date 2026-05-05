import 'dart:math' as math;

/// スタディ画面用の最小限の複素数（依存追加なし）
class QComplex {
  const QComplex(this.re, this.im);

  final double re;
  final double im;

  static const QComplex zero = QComplex(0, 0);
  static const QComplex one = QComplex(1, 0);
  static const QComplex i = QComplex(0, 1);

  factory QComplex.real(double x) => QComplex(x, 0);

  factory QComplex.polar(double r, double phi) =>
      QComplex(r * math.cos(phi), r * math.sin(phi));

  double normSquared() => re * re + im * im;

  double abs() => math.sqrt(normSquared());

  /// 偏角 \([-π, π]\)
  double arg() => math.atan2(im, re);

  QComplex conj() => QComplex(re, -im);

  QComplex operator -() => QComplex(-re, -im);

  QComplex operator +(QComplex o) => QComplex(re + o.re, im + o.im);

  QComplex operator -(QComplex o) => QComplex(re - o.re, im - o.im);

  QComplex operator *(QComplex o) =>
      QComplex(re * o.re - im * o.im, re * o.im + im * o.re);

  QComplex scaled(double s) => QComplex(re * s, im * s);
}
