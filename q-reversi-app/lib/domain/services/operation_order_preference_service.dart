import 'package:shared_preferences/shared_preferences.dart';

/// ゲート／盤面の操作順設定
///
/// デフォルトはゲート先行。`true` のとき従来どおり順不同。
class OperationOrderPreferenceService {
  static const String _freeSelectionOrderKey = 'allow_free_selection_order';

  /// ゲートとマスを好きな順で選べるか（デフォルト: false = ゲート先行）
  Future<bool> isFreeSelectionOrderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_freeSelectionOrderKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setFreeSelectionOrderEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_freeSelectionOrderKey, enabled);
    } catch (_) {
      // 保存失敗は致命的ではない
    }
  }
}
