import 'package:shared_preferences/shared_preferences.dart';

class StudyTextProgressService {
  StudyTextProgressService._();

  static String _key(String screenId) => 'study_text_tutorial_seen_$screenId';

  static Future<bool> hasSeen(String screenId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(screenId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen(String screenId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(screenId), true);
    } catch (_) {
      // no-op
    }
  }
}
