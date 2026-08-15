import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore の one-shot get を短時間リトライする。
///
/// Web では Auth / App Check トークン準備前の permission-denied が起きやすい。
class FirestoreGetWithRetry {
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const int defaultAttempts = 3;

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    FirebaseFirestore firestore,
    String path, {
    Duration timeout = defaultTimeout,
    int attempts = defaultAttempts,
  }) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        return await firestore
            .doc(path)
            .get(const GetOptions(source: Source.server))
            .timeout(timeout);
      } catch (e) {
        lastError = e;
        debugPrint('Firestore get $path attempt ${i + 1}/$attempts failed: $e');
        if (i < attempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
        }
      }
    }

    try {
      return await firestore.doc(path).get().timeout(timeout);
    } catch (e) {
      debugPrint('Firestore get $path cache/default fallback failed: $e');
      throw lastError ?? e;
    }
  }
}
