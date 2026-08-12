import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../entities/challenge_level.dart';
import '../entities/board.dart';
import '../entities/piece.dart';
import '../entities/piece_type.dart';
import '../entities/gate_type.dart';
import '../entities/position.dart';

/// チャレンジレベル読み込みサービス
class ChallengeLevelLoader {
  static const String _csvPath = 'q-reversi_challange-mode.csv';

  /// すべてのレベルを読み込む
  Future<List<ChallengeLevel>> loadAllLevels() async {
    try {
      final String csvString = await rootBundle.loadString(_csvPath);
      // Windows/Unix どちらの改行でも1行ずつ解釈できるように正規化する
      final normalized = csvString
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      final List<List<dynamic>> csvData =
          const CsvToListConverter(eol: '\n').convert(normalized);

      if (csvData.length < 4) {
        throw Exception('CSVファイルのフォーマットが不正です');
      }

      final List<ChallengeLevel> levels = [];
      int i = 3; // 4行目から開始（インデックス3）

      while (i < csvData.length) {
        // level行（ヘッダー）を探す
        if (csvData[i].isNotEmpty && csvData[i][0]?.toString().trim().toLowerCase() == 'level') {
          // 次の行がデータ行（数値が入っている）
          if (i + 1 < csvData.length) {
            final level = _parseLevel(csvData, i + 1);
            if (level != null) {
              levels.add(level);
            }
          }
          // 次のレベルまでスキップ（盤面データ8行 + 座標行1行 + level行1行 + データ行1行 = 11行）
          i += 11;
        } else {
          i++;
        }
      }

      return levels;
    } catch (e) {
      throw Exception('レベルデータの読み込みに失敗しました: $e');
    }
  }

  /// 特定のレベルを読み込む
  Future<ChallengeLevel?> loadLevel(int targetLevel) async {
    final allLevels = await loadAllLevels();
    try {
      return allLevels.firstWhere((level) => level.level == targetLevel);
    } catch (e) {
      return null;
    }
  }

  /// レベルをパース
  ChallengeLevel? _parseLevel(List<List<dynamic>> csvData, int startIndex) {
    try {
      // level行: level, turn, available gate, victory condition, difficulty, ..., comment
      if (startIndex >= csvData.length) return null;
      final levelRow = csvData[startIndex];
      
      final levelNumber =
          ChallengeLevel.parseLevelId(levelRow[0]?.toString() ?? '');
      if (levelNumber == null) return null;

      final optimalTurns = int.tryParse(levelRow[1]?.toString().trim() ?? '') ?? 1;
      
      final availableGatesStr = levelRow[2]?.toString().trim() ?? '';
      final availableGates = _parseAvailableGates(availableGatesStr);

      final victoryConditionStr = levelRow[3]?.toString().trim() ?? '';
      final victoryCondition = VictoryConditionExtension.fromString(victoryConditionStr) ?? 
          VictoryCondition.allWhite;

      final difficulty =
          int.tryParse(levelRow.length > 4 ? levelRow[4]?.toString().trim() ?? '' : '') ??
              1;

      // comment は difficulty 追加後の末尾列（index 14）
      final comment =
          levelRow.length > 14 ? levelRow[14]?.toString().trim() ?? '' : '';

      // 盤面データを読み込む（次の行から8行）
      final boardStartIndex = startIndex + 2; // 座標行をスキップ
      final board = _parseBoard(csvData, boardStartIndex);

      return ChallengeLevel(
        level: levelNumber,
        optimalTurns: optimalTurns,
        availableGates: availableGates,
        victoryCondition: victoryCondition,
        initialBoard: board,
        comment: comment,
        difficulty: difficulty,
      );
    } catch (e) {
      return null;
    }
  }

  /// 使用可能ゲートをパース
  List<GateType> _parseAvailableGates(String gatesStr) {
    if (gatesStr.isEmpty) return [];
    
    final gates = <GateType>[];
    final parts = gatesStr.split(',').map((s) => s.trim()).toList();
    
    for (final part in parts) {
      // "X/H" のような形式も対応
      final subParts = part.split('/').map((s) => s.trim()).toList();
      for (final subPart in subParts) {
        final gate = GateTypeExtension.fromString(subPart);
        if (gate != null && !gates.contains(gate)) {
          gates.add(gate);
        }
      }
    }
    
    return gates;
  }

  /// 盤面をパース
  Board _parseBoard(List<List<dynamic>> csvData, int startIndex) {
    final board = Board.create8x8();
    var newBoard = board;

    // 8行の盤面データを読み込む
    for (int row = 0; row < 8; row++) {
      final dataIndex = startIndex + row;
      if (dataIndex >= csvData.length) break;

      final rowData = csvData[dataIndex];
      // 列データは5列目から開始（インデックス5-12）
      for (int col = 0; col < 8; col++) {
        final colIndex = col + 5; // CSVの列インデックス
        if (colIndex < rowData.length) {
          final pieceStr = rowData[colIndex]?.toString().trim() ?? '';
          final pieceType = PieceTypeExtension.fromString(pieceStr);
          
          if (pieceType != null) {
            final position = Position(row, col);
            final piece = Piece(
              id: 'piece_${row}_$col',
              type: pieceType,
              position: position,
            );
            newBoard = newBoard.setPiece(row, col, piece);
          }
        }
      }
    }

    return newBoard;
  }
}

