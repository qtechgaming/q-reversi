import 'dart:convert';

import '../domain/entities/board.dart';
import '../domain/entities/entangled_pair.dart';
import '../domain/entities/forbidden_area.dart';
import '../domain/entities/game_mode.dart';
import '../domain/entities/game_state.dart';
import '../domain/entities/gate_type.dart';
import '../domain/entities/piece.dart';
import '../domain/entities/piece_type.dart';
import '../domain/entities/player.dart';
import '../domain/entities/position.dart';

/// VSモード用の盤面スナップショット（永続化）
class VsGameSnapshot {
  const VsGameSnapshot({
    required this.gameState,
    required this.postGameMeasurementCompleted,
  });

  final GameState gameState;
  final bool postGameMeasurementCompleted;

  Map<String, dynamic> toJson() => {
        'postGameMeasurementCompleted': postGameMeasurementCompleted,
        'gameState': VsGameStateCodec.encodeState(gameState),
      };

  static VsGameSnapshot fromJson(Map<String, dynamic> json) {
    return VsGameSnapshot(
      postGameMeasurementCompleted:
          json['postGameMeasurementCompleted'] as bool? ?? false,
      gameState: VsGameStateCodec.decodeState(
        json['gameState'] as Map<String, dynamic>,
      ),
    );
  }

  static String encode(VsGameSnapshot snap) =>
      jsonEncode(snap.toJson());

  static VsGameSnapshot? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return VsGameSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

class VsGameStateCodec {
  static Map<String, dynamic> encodeState(GameState s) {
    return {
      'board': _encodeBoard(s.board),
      'currentPlayer': s.currentPlayer,
      'turnCount': s.turnCount,
      'maxTurns': s.maxTurns,
      'gameMode': s.gameMode.name,
      'vsMode': s.vsMode?.name,
      'players': s.players.map((k, v) => MapEntry('$k', _encodePlayer(v))),
      'forbiddenAreas': s.forbiddenAreas.map(
        (k, v) => MapEntry(
          '$k',
          v.map(_encodeForbiddenArea).toList(),
        ),
      ),
      'entangledPairs': s.entangledPairs.map(_encodeEntangledPair).toList(),
      'lastTwoBitGatePositions': s.lastTwoBitGatePositions.map(
        (k, v) => MapEntry(
          '$k',
          v.map(_encodePosition).toList(),
        ),
      ),
    };
  }

  static GameState decodeState(Map<String, dynamic> m) {
    final playersRaw = m['players'] as Map<String, dynamic>? ?? {};
    final players = <int, Player>{};
    for (final e in playersRaw.entries) {
      players[int.parse(e.key)] =
          _decodePlayer(e.value as Map<String, dynamic>);
    }

    final forbiddenRaw =
        m['forbiddenAreas'] as Map<String, dynamic>? ?? {};
    final forbiddenAreas = <int, List<ForbiddenArea>>{};
    for (final e in forbiddenRaw.entries) {
      forbiddenAreas[int.parse(e.key)] =
          (e.value as List<dynamic>).map((x) {
        return _decodeForbiddenArea(x as Map<String, dynamic>);
      }).toList();
    }

    final lastTwoRaw =
        m['lastTwoBitGatePositions'] as Map<String, dynamic>? ?? {};
    final lastTwoBit = <int, List<Position>>{};
    for (final e in lastTwoRaw.entries) {
      lastTwoBit[int.parse(e.key)] =
          (e.value as List<dynamic>).map((x) {
        return _decodePosition(x as Map<String, dynamic>);
      }).toList();
    }

    final entangledPairs = (m['entangledPairs'] as List<dynamic>? ?? [])
        .map((x) => _decodeEntangledPair(x as Map<String, dynamic>))
        .toList();

    final vsName = m['vsMode'] as String?;
    final vsMode = vsName != null
        ? VsMode.values.firstWhere((e) => e.name == vsName)
        : null;

    return GameState(
      board: _decodeBoard(m['board'] as Map<String, dynamic>),
      currentPlayer: m['currentPlayer'] as int,
      turnCount: m['turnCount'] as int,
      maxTurns: m['maxTurns'] as int,
      gameMode: GameMode.values.firstWhere((e) => e.name == m['gameMode']),
      vsMode: vsMode,
      players: players,
      forbiddenAreas: forbiddenAreas,
      entangledPairs: entangledPairs,
      lastTwoBitGatePositions: lastTwoBit,
    );
  }

  static Map<String, dynamic> _encodeBoard(Board b) {
    final rows = <List<dynamic>>[];
    for (int r = 0; r < b.rows; r++) {
      final row = <dynamic>[];
      for (int c = 0; c < b.cols; c++) {
        final p = b.pieces[r][c];
        row.add(p == null ? null : _encodePiece(p));
      }
      rows.add(row);
    }
    return {
      'rows': b.rows,
      'cols': b.cols,
      'pieces': rows,
    };
  }

  static Board _decodeBoard(Map<String, dynamic> m) {
    final rows = m['rows'] as int;
    final cols = m['cols'] as int;
    final raw = m['pieces'] as List<dynamic>;
    final pieces = <List<Piece?>>[];
    for (int r = 0; r < rows; r++) {
      final rowList = raw[r] as List<dynamic>;
      final row = <Piece?>[];
      for (int c = 0; c < cols; c++) {
        final cell = rowList[c];
        row.add(cell == null
            ? null
            : _decodePiece(cell as Map<String, dynamic>));
      }
      pieces.add(row);
    }
    return Board(pieces: pieces, rows: rows, cols: cols);
  }

  static Map<String, dynamic> _encodePiece(Piece p) {
    return {
      'id': p.id,
      'type': p.type.name,
      'row': p.position.row,
      'col': p.position.col,
      'entangledPairId': p.entangledPairId,
    };
  }

  static Piece _decodePiece(Map<String, dynamic> m) {
    final t = PieceType.values.firstWhere((e) => e.name == m['type']);
    return Piece(
      id: m['id'] as String,
      type: t,
      position: Position(m['row'] as int, m['col'] as int),
      entangledPairId: m['entangledPairId'] as String?,
    );
  }

  static Map<String, dynamic> _encodePlayer(Player p) {
    return {
      'id': p.id,
      'color': p.color.name,
      'cooldowns': {
        for (final e in p.cooldowns.entries) e.key.name: e.value,
      },
      'lastAppliedArea': p.lastAppliedArea == null
          ? null
          : _encodeForbiddenArea(p.lastAppliedArea!),
      'isAI': p.isAI,
      'aiDifficulty': p.aiDifficulty?.name,
    };
  }

  static Player _decodePlayer(Map<String, dynamic> m) {
    final cdRaw = m['cooldowns'] as Map<String, dynamic>? ?? {};
    final cooldowns = <GateType, int>{};
    for (final e in cdRaw.entries) {
      final gt = GateType.values.firstWhere((g) => g.name == e.key);
      cooldowns[gt] = e.value as int;
    }
    final areaRaw = m['lastAppliedArea'];
    return Player(
      id: m['id'] as int,
      color: PlayerColor.values.firstWhere((c) => c.name == m['color']),
      cooldowns: cooldowns,
      lastAppliedArea: areaRaw == null
          ? null
          : _decodeForbiddenArea(areaRaw as Map<String, dynamic>),
      isAI: m['isAI'] as bool? ?? false,
      aiDifficulty: _decodeAiDifficulty(m['aiDifficulty'] as String?),
    );
  }

  static AIDifficulty? _decodeAiDifficulty(String? name) {
    if (name == null) return null;
    return AIDifficulty.values.firstWhere((e) => e.name == name);
  }

  static Map<String, dynamic> _encodeForbiddenArea(ForbiddenArea a) {
    return {
      'type': a.type.name,
      'row': a.row,
      'column': a.column,
      'positions': a.positions?.map(_encodePosition).toList(),
    };
  }

  static ForbiddenArea _decodeForbiddenArea(Map<String, dynamic> m) {
    final t = ForbiddenAreaType.values.firstWhere((e) => e.name == m['type']);
    switch (t) {
      case ForbiddenAreaType.row:
        return ForbiddenArea.row(m['row'] as int);
      case ForbiddenAreaType.column:
        return ForbiddenArea.column(m['column'] as int);
      case ForbiddenAreaType.fourPieces:
        final list = (m['positions'] as List<dynamic>)
            .map((x) => _decodePosition(x as Map<String, dynamic>))
            .toList();
        return ForbiddenArea.fourPieces(list);
    }
  }

  static Map<String, dynamic> _encodePosition(Position p) {
    return {'row': p.row, 'col': p.col};
  }

  static Position _decodePosition(Map<String, dynamic> m) {
    return Position(m['row'] as int, m['col'] as int);
  }

  static Map<String, dynamic> _encodeEntangledPair(EntangledPair e) {
    return {
      'id': e.id,
      'p1': _encodePosition(e.position1),
      'p2': _encodePosition(e.position2),
    };
  }

  static EntangledPair _decodeEntangledPair(Map<String, dynamic> m) {
    return EntangledPair(
      id: m['id'] as String,
      position1: _decodePosition(m['p1'] as Map<String, dynamic>),
      position2: _decodePosition(m['p2'] as Map<String, dynamic>),
    );
  }
}
