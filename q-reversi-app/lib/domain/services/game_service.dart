import '../entities/game_state.dart';
import '../entities/gate_type.dart';
import '../entities/position.dart';
import '../entities/forbidden_area.dart';
import '../entities/player.dart';
import '../entities/piece_type.dart';
import '../entities/piece.dart';
import '../entities/game_mode.dart';
import 'gate_service.dart';

/// ゲームサービス
class GameService {
  final GateService _gateService = GateService();
  
  /// ゲートを適用（完全な処理）
  GameState applyGateWithFullLogic(
    GameState gameState,
    GateType gate,
    List<Position> targetPositions,
  ) {
    final currentPlayer = gameState.getCurrentPlayer();
    if (currentPlayer == null) return gameState;

    // クールタイムチェック（フリーラン / チャレンジ / TIME ATTACK ではスキップ）
    if (gameState.gameMode != GameMode.freeRun && 
        gameState.gameMode != GameMode.challenge &&
        gameState.gameMode != GameMode.timeAttack &&
        !currentPlayer.canUseGate(gate)) {
      return gameState; // エラー: クールタイム中
    }
    
    // 禁止領域チェック（1ビットゲートのみ適用、フリーラン / チャレンジ / TIME ATTACK ではスキップ）
    if (gate.isOneBitGate && 
        gameState.gameMode != GameMode.freeRun && 
        gameState.gameMode != GameMode.challenge &&
        gameState.gameMode != GameMode.timeAttack) {
      // 禁止領域は「次の相手ターン」用として set されるため、
      // 適用時点では“現在手番プレイヤーの forbiddenAreas”を参照して拒否する。
      final currentForbiddenAreas = gameState.getForbiddenAreas(currentPlayer.id);
      for (final area in currentForbiddenAreas) {
        if (_isTargetForbidden(area, gate, targetPositions)) {
          return gameState; // エラー: 禁止領域
        }
      }
    }
    
    // エンタングルメントチェック（仕様: エンタングルされた駒にはゲート操作不可）
    // ただし、1ビットゲートの場合は適用範囲が止まるか、その駒のみスキップされる
    // 2ビットゲートの場合は完全に適用不可
    if (gate.isOneBitGate && targetPositions.length == 4) {
      // UI仕様と揃える: 4マス選択にエンタングル駒を含む場合は手を拒否
      for (final position in targetPositions) {
        final piece = gameState.board.getPiece(position.row, position.col);
        if (piece != null && piece.isEntangled) {
          return gameState; // エラー: エンタングルを含む4マス選択
        }
      }
    }

    if (gate.isTwoBitGate) {
      for (final position in targetPositions) {
        final piece = gameState.board.getPiece(position.row, position.col);
        if (piece != null && piece.isEntangled) {
          return gameState; // エラー: エンタングル状態（2ビットゲートは完全に適用不可）
        }
      }
    }

    // 行／列1列（8マス）: GateService はエンタングルで break する。禁止マスはスキップするので、
    // 「禁止だけを跨いだあと、まだ1マスも適用できないうちにエンタングルで止まる」場合は手を拒否する。
    if (gate.isOneBitGate && targetPositions.length == 8) {
      if (_oneBitLineStoppedByEntanglementWithNoApply(
            gameState,
            targetPositions,
            currentPlayer.id,
          )) {
        return gameState;
      }
    }

    // ゲートを適用
    var newState = _gateService.applyGate(gameState, gate, targetPositions);

    // VSモードで、今回の2ビットゲート適用によってエンタングルが生成された場合
    // 次の相手ターンの禁止領域として「エンタングルした2駒の行・列」を追加する
    final entanglementForbiddenAreas = <ForbiddenArea>[];
    if (gameState.gameMode == GameMode.vs &&
        gate.isTwoBitGate &&
        targetPositions.length == 2) {
      final pos1 = targetPositions[0];
      final pos2 = targetPositions[1];
      final piece1 = newState.board.getPiece(pos1.row, pos1.col);
      final piece2 = newState.board.getPiece(pos2.row, pos2.col);

      final isEntangledNow =
          (piece1 != null && piece1.isEntangled) ||
          (piece2 != null && piece2.isEntangled);

      if (isEntangledNow) {
        final addedKeys = <String>{};

        void addForbiddenRow(int row) {
          final key = 'row:$row';
          if (addedKeys.add(key)) {
            entanglementForbiddenAreas.add(ForbiddenArea.row(row));
          }
        }

        void addForbiddenColumn(int col) {
          final key = 'col:$col';
          if (addedKeys.add(key)) {
            entanglementForbiddenAreas.add(ForbiddenArea.column(col));
          }
        }

        addForbiddenRow(pos1.row);
        addForbiddenColumn(pos1.col);
        addForbiddenRow(pos2.row);
        addForbiddenColumn(pos2.col);
      }
    }
    
    // クールタイムを更新（フリーラン / チャレンジ / TIME ATTACK ではクールタイムを設定しない）
    final updatedPlayer = (gameState.gameMode == GameMode.freeRun ||
            gameState.gameMode == GameMode.challenge ||
            gameState.gameMode == GameMode.timeAttack)
        ? currentPlayer
        : currentPlayer.useGate(gate);
    final newPlayers = Map<int, Player>.from(newState.players);
    newPlayers[currentPlayer.id] = updatedPlayer;
    
    // フリーラン / チャレンジ / TIME ATTACK の場合はターンを進めるが、プレイヤーは変更しない
    if (gameState.gameMode == GameMode.freeRun ||
        gameState.gameMode == GameMode.challenge ||
        gameState.gameMode == GameMode.timeAttack) {
      // クールタイムを減少（自分のクールタイムを減少）
      final decreasedPlayer = updatedPlayer.decreaseCooldowns();
      newPlayers[currentPlayer.id] = decreasedPlayer;
      
      return newState.copyWith(
        players: newPlayers,
        turnCount: newState.turnCount + 1,
        // チャレンジモードとフリーランモードではcurrentPlayerを変更しない
        currentPlayer: gameState.currentPlayer,
      );
    }
    
    // 禁止領域を設定（仕様: 相手の次のターンのみ有効）
    final forbiddenArea = _createForbiddenArea(gate, targetPositions);
    final newForbiddenAreas = Map<int, List<ForbiddenArea>>.from(newState.forbiddenAreas);
    final opponentId = newState.currentPlayer == 1 ? 2 : 1;
    
    // 現在のプレイヤーの禁止領域をクリア（自分のターンが終了したら）
    newForbiddenAreas[currentPlayer.id] = [];
    
    // 相手の禁止領域を設定
    newForbiddenAreas[opponentId] = entanglementForbiddenAreas.isNotEmpty
        ? entanglementForbiddenAreas
        : [forbiddenArea];
    
    // 2ビットゲートが適用された場合、位置を記録（次のターンのプレイヤーに設定）
    final newLastTwoBitGatePositions = Map<int, List<Position>>.from(newState.lastTwoBitGatePositions);
    if (gate.isTwoBitGate && targetPositions.length == 2) {
      // 現在のプレイヤーの記録をクリア
      newLastTwoBitGatePositions[currentPlayer.id] = [];
      // 次のターンのプレイヤー（相手）に記録
      newLastTwoBitGatePositions[opponentId] = List.from(targetPositions);
    } else {
      // 1ビットゲートの場合は、現在のプレイヤーの記録をクリア
      newLastTwoBitGatePositions[currentPlayer.id] = [];
    }
    
    // ターンを進める
    final nextPlayer = newState.currentPlayer == 1 ? 2 : 1;
    final nextPlayerObj = newPlayers[nextPlayer];
    if (nextPlayerObj != null) {
      // 相手のクールタイムを減少
      newPlayers[nextPlayer] = nextPlayerObj.decreaseCooldowns();
    }
    
    // 禁止領域は次のターンのプレイヤー（opponentId）に設定されているので、
    // そのまま使用する（クリアしない）
    
    return newState.copyWith(
      players: newPlayers,
      forbiddenAreas: newForbiddenAreas,
      lastTwoBitGatePositions: newLastTwoBitGatePositions,
      currentPlayer: nextPlayer,
      turnCount: newState.turnCount + 1,
    );
  }
  
  /// [GateService] の行／列走査と同じ順序で、適用前にエンタングルで止まり1マスも変えられないか。
  bool _oneBitLineStoppedByEntanglementWithNoApply(
    GameState gameState,
    List<Position> positions,
    int playerId,
  ) {
    final forbiddenAreas = gameState.getForbiddenAreas(playerId);
    bool isPositionForbidden(Position position) {
      for (final area in forbiddenAreas) {
        if (area.type == ForbiddenAreaType.row && area.row == position.row) {
          return true;
        }
        if (area.type == ForbiddenAreaType.column && area.column == position.col) {
          return true;
        }
        if (area.type == ForbiddenAreaType.fourPieces &&
            area.positions != null &&
            area.positions!.any((p) => p == position)) {
          return true;
        }
      }
      return false;
    }

    var wouldApplyBeforeEntangledBreak = false;
    for (final position in positions) {
      final piece = gameState.board.getPiece(position.row, position.col);
      if (piece == null) continue;
      if (piece.isEntangled) {
        return !wouldApplyBeforeEntangledBreak;
      }
      if (isPositionForbidden(position)) continue;
      wouldApplyBeforeEntangledBreak = true;
    }
    return false;
  }

  /// ターゲットが禁止領域かどうか
  ///
  /// 行・列の禁止は「その行／列全体を対象にした手」のみ拒否する。
  /// 列選択で禁止行と1マスだけ交差する場合など、GateService 側でスキップして
  /// 続きのマスに適用できるケースはここでは拒否しない。
  bool _isTargetForbidden(
    ForbiddenArea area,
    GateType gate,
    List<Position> targetPositions,
  ) {
    if (gate.isOneBitGate) {
      if (area.type == ForbiddenAreaType.row &&
          area.row != null &&
          targetPositions.isNotEmpty) {
        final r = area.row!;
        return targetPositions.every((p) => p.row == r);
      }
      if (area.type == ForbiddenAreaType.column &&
          area.column != null &&
          targetPositions.isNotEmpty) {
        final c = area.column!;
        return targetPositions.every((p) => p.col == c);
      }
      if (area.type == ForbiddenAreaType.fourPieces) {
        return area.isFourPiecesForbidden(targetPositions);
      }
    }
    return false;
  }
  
  /// 禁止領域を作成
  ForbiddenArea _createForbiddenArea(
    GateType gate,
    List<Position> targetPositions,
  ) {
    if (gate.isOneBitGate) {
      if (targetPositions.length == 8) {
        // 行または列
        if (targetPositions.every((p) => p.row == targetPositions.first.row)) {
          return ForbiddenArea.row(targetPositions.first.row);
        }
        if (targetPositions.every((p) => p.col == targetPositions.first.col)) {
          return ForbiddenArea.column(targetPositions.first.col);
        }
      }
      if (targetPositions.length == 4) {
        // 4マス選択
        return ForbiddenArea.fourPieces(targetPositions);
      }
    }
    // 2ビットゲートには禁止領域なし
    return ForbiddenArea.fourPieces(const []);
  }
  
  /// 初期盤面を生成（ランダム、各タイプ25%）
  GameState createInitialBoard(GameState gameState) {
    final board = gameState.board;
    final totalCells = board.rows * board.cols;
    final piecesPerType = totalCells ~/ 4; // 各タイプ25%
    
    // 各タイプ16個ずつ（8×8の場合）
    final types = [
      PieceType.white,
      PieceType.black,
      PieceType.grayPlus,
      PieceType.grayMinus,
    ];
    final allPositions = <Position>[];
    
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        allPositions.add(Position(r, c));
      }
    }
    
    allPositions.shuffle();
    
    // 各タイプのリストを作成
    final typeList = <PieceType>[];
    for (int i = 0; i < types.length; i++) {
      for (int j = 0; j < piecesPerType; j++) {
        typeList.add(types[i]);
      }
    }
    // 残りのマス（割り切れない場合）をランダムに割り当て
    while (typeList.length < totalCells) {
      typeList.add(types[typeList.length % types.length]);
    }
    typeList.shuffle();
    
    var newBoard = board;
    for (int i = 0; i < allPositions.length && i < typeList.length; i++) {
      final position = allPositions[i];
      final type = typeList[i];
      final piece = Piece(
        id: 'piece_${position.row}_${position.col}',
        type: type,
        position: position,
      );
      newBoard = newBoard.setPiece(position.row, position.col, piece);
    }
    
    return gameState.copyWith(board: newBoard);
  }
  
  /// 盤面をすべて白または黒にする
  GameState setAllPiecesToColor(GameState gameState, bool isWhite) {
    final board = gameState.board;
    final pieceType = isWhite ? PieceType.white : PieceType.black;
    
    var newBoard = board;
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final position = Position(r, c);
        final piece = Piece(
          id: 'piece_${r}_$c',
          type: pieceType,
          position: position,
        );
        newBoard = newBoard.setPiece(r, c, piece);
      }
    }
    
    return gameState.copyWith(board: newBoard);
  }
}

