import 'package:flutter/material.dart';
import '../../domain/services/operation_order_preference_service.dart';

/// 操作順設定ダイアログを表示し、変更後の「順不同」値を返す。
Future<bool?> showOperationOrderSettingsDialog(BuildContext context) async {
  final service = OperationOrderPreferenceService();
  var allowFree = await service.isFreeSelectionOrderEnabled();
  if (!context.mounted) return null;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: const Text(
              '操作設定',
              style: TextStyle(color: Colors.white),
            ),
            content: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ゲートと駒を好きな順で選ぶ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'オンにするとゲートと駒を順不同で選ぶことができます',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: allowFree,
              activeColor: const Color(0xFF4CAF50),
              onChanged: (value) async {
                await service.setFreeSelectionOrderEnabled(value);
                setDialogState(() {
                  allowFree = value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(allowFree),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    },
  );
}
