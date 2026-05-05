import 'qcomplex.dart';

/// グローバル位相を除いた代表として、計算基底の**辞書順で最初の非ゼロ振幅**を
/// **正の実数**に揃える。
///
/// ベクトル全体に \( e^{-i\arg \alpha_k} = \bar\alpha_k / |\alpha_k| \) を掛ける。
/// （「実数優先・正の実数優先」＝先頭から見て最初に現れる成分を基準にする。）
///
/// 相対位相は変わらない。全成分がゼロに近いときは [v] をそのまま返す。
List<QComplex> globalPhaseGaugeFirstPositive(
  List<QComplex> v, {
  double eps = 1e-12,
}) {
  for (var i = 0; i < v.length; i++) {
    final a = v[i];
    if (a.abs() > eps) {
      final invAbs = 1.0 / a.abs();
      final g = a.conj().scaled(invAbs);
      return [for (final z in v) z * g];
    }
  }
  return List<QComplex>.from(v);
}
