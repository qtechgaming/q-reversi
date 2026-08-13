import 'dart:math';

/// ユーザー識別とデフォルト表示名。
///
/// 識別子は Firebase Anonymous Auth の UID（Phase 1 では同形式のローカルUID）。
/// 表示名はグローバル一意。未設定時は `QMaster` + 未使用の最小正整数。
class TimeAttackPlayerIdentity {
  static const String namePrefix = 'QMaster';
  static const int maxPlayerNameLength = 12;
  static const int firebaseUidLength = 28;

  /// `QMaster99999` が 12 文字。これより大きい番号は使えない。
  static const int maxNumericSuffix = 99999;

  static const String _uidAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// Firebase UID と同じ 28 文字の英数字。Phase 2 で Auth UID に置き換える。
  static String generateLocalUid({Random? random}) {
    final rng = random ?? Random.secure();
    return List.generate(
      firebaseUidLength,
      (_) => _uidAlphabet[rng.nextInt(_uidAlphabet.length)],
    ).join();
  }

  /// 未使用の最も小さい番号のデフォルト名。例: QMaster1
  static String nextDefaultNickname(Iterable<String> takenNames) {
    final taken = takenNames.toSet();
    for (var n = 1; n <= maxNumericSuffix; n++) {
      final name = '$namePrefix$n';
      if (!taken.contains(name)) return name;
    }
    return '$namePrefix$maxNumericSuffix';
  }

  static bool isTaken(
    String name, {
    required Iterable<String> takenNames,
    String? allowedCurrent,
  }) {
    if (allowedCurrent != null && name == allowedCurrent) return false;
    return takenNames.contains(name);
  }
}
