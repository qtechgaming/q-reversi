import '../entities/board.dart';
import '../entities/piece_type.dart';
import '../entities/position.dart';

enum VsTutorialTargetKind { row, column, fourPieces }

/// Xゲート適用後、白番として自分の駒が最も増える候補
class VsTutorialBestTarget {
  const VsTutorialBestTarget({
    required this.kind,
    required this.positions,
    required this.netGain,
    required this.blackFlips,
    required this.label,
    this.row,
    this.column,
  });

  final VsTutorialTargetKind kind;
  final List<Position> positions;

  /// 白の純増（黒→白 − 白→黒）。自分の駒の増え分
  final int netGain;

  /// 黒→白になる枚数（説明用）
  final int blackFlips;
  final String label;
  final int? row;
  final int? column;
}

/// VSチュートリアル用: 白番が X で自分の駒を最も増やせる場所の評価
class VsTutorialXFlipHelper {
  const VsTutorialXFlipHelper._();

  /// 対象マスのうち、Xで黒→白になる枚数（白番視点）
  static int countBlackToWhiteFlips(Board board, List<Position> positions) {
    var count = 0;
    for (final pos in positions) {
      final piece = board.getPiece(pos.row, pos.col);
      if (piece?.type == PieceType.black) {
        count++;
      }
    }
    return count;
  }

  /// 白番の純増（黒→白 − 白→黒）
  static int netWhiteGain(Board board, List<Position> positions) {
    var black = 0;
    var white = 0;
    for (final pos in positions) {
      final piece = board.getPiece(pos.row, pos.col);
      if (piece?.type == PieceType.black) black++;
      if (piece?.type == PieceType.white) white++;
    }
    return black - white;
  }

  static bool _isBetter(
    int candidateNetGain,
    int candidateBlackFlips,
    VsTutorialBestTarget? current,
  ) {
    if (current == null) return true;
    if (candidateNetGain != current.netGain) {
      return candidateNetGain > current.netGain;
    }
    // 純増が同じなら、黒を多く白に変えられる方を優先
    return candidateBlackFlips > current.blackFlips;
  }

  /// 行・列を優先して、自分の駒の純増が最大の候補を返す
  static VsTutorialBestTarget findBestTarget(Board board) {
    VsTutorialBestTarget? best;

    void consider({
      required VsTutorialTargetKind kind,
      required List<Position> positions,
      required String label,
      int? row,
      int? column,
    }) {
      final net = netWhiteGain(board, positions);
      final blacks = countBlackToWhiteFlips(board, positions);
      if (!_isBetter(net, blacks, best)) return;
      best = VsTutorialBestTarget(
        kind: kind,
        row: row,
        column: column,
        positions: positions,
        netGain: net,
        blackFlips: blacks,
        label: label,
      );
    }

    for (int r = 0; r < board.rows; r++) {
      final positions = [
        for (int c = 0; c < board.cols; c++) Position(r, c),
      ];
      consider(
        kind: VsTutorialTargetKind.row,
        row: r,
        positions: positions,
        label: '${r + 1}行目',
      );
    }
    for (int c = 0; c < board.cols; c++) {
      final positions = [
        for (int r = 0; r < board.rows; r++) Position(r, c),
      ];
      consider(
        kind: VsTutorialTargetKind.column,
        column: c,
        positions: positions,
        label: '${c + 1}列目',
      );
    }

    // 行・列より純増が明確に多い場合のみ4マスを採用（見やすさ優先）
    final rowColBest = best;
    for (int r = 0; r < board.rows - 1; r++) {
      for (int c = 0; c < board.cols - 1; c++) {
        final positions = [
          Position(r, c),
          Position(r, c + 1),
          Position(r + 1, c),
          Position(r + 1, c + 1),
        ];
        final net = netWhiteGain(board, positions);
        if (rowColBest == null || net > rowColBest.netGain) {
          consider(
            kind: VsTutorialTargetKind.fourPieces,
            positions: positions,
            label: '${r + 1}行${c + 1}列付近の4マス',
          );
        }
      }
    }

    return best ??
        VsTutorialBestTarget(
          kind: VsTutorialTargetKind.row,
          row: 0,
          positions: [for (int c = 0; c < board.cols; c++) Position(0, c)],
          netGain: 0,
          blackFlips: 0,
          label: '1行目',
        );
  }

  /// 現在の選択が指定ターゲットと一致するか
  static bool matchesTarget(
    VsTutorialBestTarget target, {
    required int? selectedRow,
    required int? selectedColumn,
    required List<Position> selectedPositions,
  }) {
    switch (target.kind) {
      case VsTutorialTargetKind.row:
        return selectedRow == target.row;
      case VsTutorialTargetKind.column:
        return selectedColumn == target.column;
      case VsTutorialTargetKind.fourPieces:
        if (selectedPositions.length != target.positions.length) return false;
        final selected = selectedPositions.toSet();
        return target.positions.every(selected.contains);
    }
  }
}
