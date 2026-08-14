import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/firebase/ranking_data_deletion_service.dart';
import '../../data/firebase/time_attack_run_remote_service.dart';

/// 公開ドキュメント URL（GitHub Pages）
abstract final class AppLegalLinks {
  static const privacyPolicy =
      'https://qtechgaming.github.io/q-reversi-privacy-policy/';
  static const support = 'https://qtechgaming.github.io/support-ja/';

  static Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// プライバシーポリシー / サポートへの導線
Future<void> showAppLegalInfoSheet(BuildContext context) {
  final parentContext = context;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1F3A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'ヘルプ・情報',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: Colors.white70),
                title: const Text(
                  'プライバシーポリシー',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.open_in_new,
                    color: Colors.white38, size: 18),
                onTap: () => _openLink(
                  context,
                  AppLegalLinks.privacyPolicy,
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.support_agent, color: Colors.white70),
                title: const Text(
                  'サポート',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.open_in_new,
                    color: Colors.white38, size: 18),
                onTap: () => _openLink(
                  context,
                  AppLegalLinks.support,
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.white38),
                title: const Text(
                  'ランキングデータの削除',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                subtitle: const Text(
                  '表示名・スコア・勝利数など',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showRankingDataDeletionDialog(parentContext);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openLink(BuildContext context, String url) async {
  final ok = await AppLegalLinks.open(url);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ページを開けませんでした')),
    );
  }
}

/// ランキング関連データの削除。確認を2回求める。
Future<void> showRankingDataDeletionDialog(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'ランキングデータを削除',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'タイムアタックの記録、VS量子AIの勝利数、プレイヤー名など、ランキングに関わるデータがサーバーとこの端末から削除されます。\n\n'
          'チャレンジの進行や操作設定は消えません。この操作は取り消せません。',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '続ける',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );
  if (first != true || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          '本当に削除しますか？',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'クラウドデータとともに、この端末の関連データも削除されます。',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '削除する',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                '削除しています…',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    },
  );

  String? error;
  try {
    await RankingDataDeletionService().deleteAllRankingData();
  } catch (e) {
    error = e is TimeAttackRunRemoteException
        ? e.message
        : 'ランキングデータの削除に失敗しました';
  }
  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          error == null ? '削除しました' : '削除できませんでした',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          error ?? 'ランキングに関わるデータは削除されました。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
