import '../entities/game_state.dart';
import '../entities/challenge_level.dart';
import '../entities/piece_type.dart';
import '../entities/player.dart';
import '../entities/game_mode.dart';

/// チャレンジゲームサービス
class ChallengeGameService {
  /// 勝利条件をチェック
  bool checkVictoryCondition(GameState gameState, VictoryCondition condition) {
    final board = gameState.board;
    bool allMatch = true;

    for (int row = 0; row < board.rows; row++) {
      for (int col = 0; col < board.cols; col++) {
        final piece = board.getPiece(row, col);
        
        if (piece == null) {
          allMatch = false;
          continue;
        }

        switch (condition) {
          case VictoryCondition.allWhite:
            if (piece.type != PieceType.white) {
              allMatch = false;
            }
            break;
          case VictoryCondition.allBlack:
            if (piece.type != PieceType.black) {
              allMatch = false;
            }
            break;
        }

        if (!allMatch) break;
      }
      if (!allMatch) break;
    }

    return allMatch;
  }

  /// チャレンジ用のGameStateを作成
  GameState createChallengeGameState(
    ChallengeLevel level, {
    GameMode gameMode = GameMode.challenge,
  }) {
    final board = level.initialBoard;
    
    return GameState(
      board: board,
      gameMode: gameMode,
      currentPlayer: 1,
      turnCount: 0,
      maxTurns: 999999, // ターン制限を廃止（実質無制限）
      players: const {
        1: Player(
          id: 1,
          color: PlayerColor.black,
        ),
      },
    );
  }
}

