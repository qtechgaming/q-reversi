import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

/// Challenge CSV から Server 用 catalog を生成する。
/// 実行: `dart run tool/generate_time_attack_catalog.dart`
void main() {
  final csvFile = File('q-reversi_challange-mode.csv');
  if (!csvFile.existsSync()) {
    stderr.writeln('q-reversi_challange-mode.csv が見つかりません');
    exit(1);
  }

  final normalized = csvFile
      .readAsStringSync()
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  final rows = const CsvToListConverter(eol: '\n').convert(normalized);

  final catalog = <Map<String, Object>>[];
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].isEmpty) continue;
    if (rows[i][0]?.toString().trim().toLowerCase() != 'level') continue;
    if (i + 1 >= rows.length) continue;
    final data = rows[i + 1];
    final parsed = _parseLevel(data);
    if (parsed == null) continue;
    if (!_inPool(parsed.levelId)) continue;
    catalog.add({
      'levelId': parsed.levelId,
      'displayLabel': parsed.displayLabel,
      'optimalTurns': parsed.optimalTurns,
      'difficulty': parsed.difficulty,
      'score': parsed.optimalTurns + parsed.difficulty,
    });
  }

  catalog.sort((a, b) => (a['levelId'] as int).compareTo(b['levelId'] as int));

  final outDir = Directory('functions/src/generated');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/time_attack_level_catalog.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(catalog));
  stdout.writeln('wrote ${outFile.path} (${catalog.length} levels)');
}

bool _inPool(int levelId) {
  if (levelId >= 901 && levelId <= 915) return true;
  return levelId >= 1 && levelId <= 300;
}

class _Parsed {
  final int levelId;
  final String displayLabel;
  final int optimalTurns;
  final int difficulty;
  const _Parsed({
    required this.levelId,
    required this.displayLabel,
    required this.optimalTurns,
    required this.difficulty,
  });
}

_Parsed? _parseLevel(List<dynamic> row) {
  if (row.isEmpty) return null;
  final raw = row[0]?.toString().trim() ?? '';
  final levelId = _parseLevelId(raw);
  if (levelId == null) return null;
  final turns = int.tryParse(row.length > 1 ? row[1]?.toString().trim() ?? '' : '') ?? 1;
  final difficulty =
      int.tryParse(row.length > 4 ? row[4]?.toString().trim() ?? '' : '') ?? 1;
  return _Parsed(
    levelId: levelId,
    displayLabel: raw,
    optimalTurns: turns,
    difficulty: difficulty.clamp(1, 10),
  );
}

int? _parseLevelId(String raw) {
  if (raw.isEmpty) return null;
  final stage0 = RegExp(r'^0-(\d+)$').firstMatch(raw);
  if (stage0 != null) {
    final n = int.tryParse(stage0.group(1)!);
    if (n == null || n < 1 || n > 15) return null;
    return 900 + n;
  }
  return int.tryParse(raw);
}
