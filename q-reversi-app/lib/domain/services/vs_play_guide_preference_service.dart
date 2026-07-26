import 'package:shared_preferences/shared_preferences.dart';

/// VSモード初回プレイガイドの表示済みフラグ
class VsPlayGuidePreferenceService {
  static const String _prefsKey = 'vs_play_guide_shown';

  Future<bool> isShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
