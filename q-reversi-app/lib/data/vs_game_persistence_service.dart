import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/game_mode.dart';
import 'vs_game_state_codec.dart';

/// VSモードの途中盤面を永続化（タスクキル後の再開用）
class VsGamePersistenceService {
  static const _keySnapshot = 'q_reversi_vs_game_snapshot_v1';

  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySnapshot);
    if (raw == null || raw.isEmpty) return false;
    final snap = VsGameSnapshot.decode(raw);
    return snap != null && snap.gameState.gameMode == GameMode.vs;
  }

  Future<void> saveSnapshot(VsGameSnapshot snap) async {
    if (snap.gameState.gameMode != GameMode.vs) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySnapshot, VsGameSnapshot.encode(snap));
  }

  Future<VsGameSnapshot?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySnapshot);
    final snap = VsGameSnapshot.decode(raw);
    if (snap == null || snap.gameState.gameMode != GameMode.vs) {
      return null;
    }
    return snap;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySnapshot);
  }
}
