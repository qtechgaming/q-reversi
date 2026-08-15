import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Firebase 初期化・App Check・Anonymous Auth
class FirebaseBootstrap {
  /// Web 本番用 reCAPTCHA v3 サイトキー（未設定時は WebDebugProvider）
  ///
  /// 例: flutter run --dart-define=RECAPTCHA_SITE_KEY=xxxxx
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
  );

  /// 失敗してもアプリは起動する。UID はローカルフォールバックになる。
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activateAppCheck();
    await ensureSignedIn();
    await waitForAppCheckToken();
  }

  /// App Check を有効化（Debug では Debug Provider）
  static Future<void> activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerWeb: _webProvider(),
      );
      if (kDebugMode) {
        debugPrint(
          'Firebase App Check: activated '
          '(debug provider — Console に debug token を登録してください)',
        );
      }
    } catch (e, st) {
      debugPrint('Firebase App Check の有効化に失敗しました: $e\n$st');
    }
  }

  static WebProvider _webProvider() {
    if (kDebugMode || recaptchaSiteKey.isEmpty) {
      if (!kDebugMode && recaptchaSiteKey.isEmpty) {
        debugPrint(
          'RECAPTCHA_SITE_KEY 未設定のため WebDebugProvider を使用します。'
          '本番 Web では --dart-define=RECAPTCHA_SITE_KEY=... を設定してください。',
        );
      }
      return WebDebugProvider();
    }
    return ReCaptchaV3Provider(recaptchaSiteKey);
  }

  /// Web では persistence 復元前に currentUser が null になる。
  /// 復元を待たずに匿名サインインすると別 UID になり、ランキング読み込みが失敗しやすい。
  static Future<User?> ensureSignedIn({bool forceNew = false}) async {
    if (forceNew) {
      return signInAnonymously(forceNew: true);
    }

    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      await _ensureIdToken(auth.currentUser);
      return auth.currentUser;
    }

    try {
      final restored = await auth.authStateChanges().first.timeout(
        const Duration(seconds: 8),
      );
      if (restored != null) {
        await _ensureIdToken(restored);
        return restored;
      }
    } catch (e) {
      debugPrint('Firebase Auth restore wait failed: $e');
    }
    if (auth.currentUser != null) {
      await _ensureIdToken(auth.currentUser);
      return auth.currentUser;
    }

    final user = await signInAnonymously();
    await _ensureIdToken(user);
    return user;
  }

  static Future<void> waitForAppCheckToken() async {
    try {
      await FirebaseAppCheck.instance
          .getToken()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Firebase App Check token wait failed: $e');
    }
  }

  static Future<void> _ensureIdToken(User? user) async {
    if (user == null) return;
    try {
      await user.getIdToken();
    } catch (e) {
      debugPrint('Firebase Auth getIdToken failed: $e');
    }
  }

  static Future<User?> signInAnonymously({bool forceNew = false}) async {
    final auth = FirebaseAuth.instance;
    if (forceNew) {
      try {
        await auth.signOut();
      } catch (_) {}
    } else {
      final existing = auth.currentUser;
      if (existing != null) return existing;
    }

    final credential = await auth.signInAnonymously();
    return credential.user;
  }

  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  static void logInitResult() {
    if (!kDebugMode) return;
    final uid = currentUid;
    if (uid == null) {
      debugPrint('Firebase Auth: 未サインイン（ローカルUIDを使用）');
    } else {
      debugPrint('Firebase Auth: anonymous uid=$uid');
    }
  }
}
