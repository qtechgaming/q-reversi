import 'package:flutter/material.dart';

/// TOP3 / TOP10 向けの順位ビジュアル
class TimeAttackRankStyle {
  TimeAttackRankStyle._();

  static const gold = Color(0xFFFFD54F);
  static const silver = Color(0xFFCFD8DC);
  static const bronze = Color(0xFFFFAB91);
  static const top10 = Color(0xFF80CBC4);

  static bool isTop3(int rank) => rank >= 1 && rank <= 3;
  static bool isTop10(int rank) => rank >= 1 && rank <= 10;

  static Color accentColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        if (rank <= 10) return top10;
        return Colors.white54;
    }
  }

  /// 行の薄い背景（TOP3 > TOP10）。自分行のハイライトと重ねる用。
  static Color? rowTint(int rank) {
    if (rank == 1) return gold.withValues(alpha: 0.12);
    if (rank == 2) return silver.withValues(alpha: 0.10);
    if (rank == 3) return bronze.withValues(alpha: 0.10);
    if (rank <= 10) return top10.withValues(alpha: 0.06);
    return null;
  }
}

/// 順位表示（#1 トロフィー / TOP10 強調）
class TimeAttackRankBadge extends StatelessWidget {
  const TimeAttackRankBadge({
    super.key,
    required this.rank,
    this.compact = false,
    this.forceColor,
  });

  final int rank;
  final bool compact;
  final Color? forceColor;

  @override
  Widget build(BuildContext context) {
    final color = forceColor ?? TimeAttackRankStyle.accentColor(rank);
    final fontSize = compact ? 12.0 : 15.0;
    final iconSize = compact ? 12.0 : 16.0;

    if (TimeAttackRankStyle.isTop3(rank)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rank == 1 ? Icons.emoji_events : Icons.military_tech,
            size: iconSize,
            color: color,
          ),
          SizedBox(width: compact ? 2 : 4),
          Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Text(
      compact ? '#$rank' : '$rank',
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: TimeAttackRankStyle.isTop10(rank)
            ? FontWeight.w700
            : FontWeight.bold,
      ),
    );
  }
}
