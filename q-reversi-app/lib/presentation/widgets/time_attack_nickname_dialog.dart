import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/services/time_attack_local_profile_service.dart';

/// プレイヤー名入力ダイアログ。保存成功で true、キャンセルで false。
Future<bool> showTimeAttackNicknameDialog(
  BuildContext context, {
  String? initialName,
  Iterable<String> takenNames = const [],
  String title = 'プレイヤー名を変更',
  String confirmLabel = '保存',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NicknameDialog(
      initialName: initialName ?? '',
      takenNames: takenNames,
      title: title,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({
    required this.initialName,
    required this.takenNames,
    required this.title,
    required this.confirmLabel,
  });

  final String initialName;
  final Iterable<String> takenNames;
  final String title;
  final String confirmLabel;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;
  final _profile = TimeAttackLocalProfileService();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validated =
        TimeAttackLocalProfileService.validateNickname(_controller.text);
    if (validated == null) {
      setState(() {
        _error =
            '${TimeAttackLocalProfileService.minNicknameLength}〜${TimeAttackLocalProfileService.maxNicknameLength}文字で入力してください';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _profile.setNickname(
      validated,
      takenNames: widget.takenNames,
    );
    if (!mounted) return;
    if (result != NicknameSetResult.ok) {
      setState(() {
        _saving = false;
        _error = switch (result) {
          NicknameSetResult.invalid =>
            '${TimeAttackLocalProfileService.minNicknameLength}〜${TimeAttackLocalProfileService.maxNicknameLength}文字で入力してください',
          NicknameSetResult.taken => 'その名前はすでに使われています',
          NicknameSetResult.blocked => '使用できない言葉が含まれています',
          NicknameSetResult.failed => '保存に失敗しました',
          NicknameSetResult.ok => null,
        };
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F3A),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: TimeAttackLocalProfileService.maxNicknameLength,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
            ],
            decoration: InputDecoration(
              hintText: 'ニックネーム',
              hintStyle: const TextStyle(color: Colors.white38),
              counterStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB794F4)),
              ),
              errorText: _error,
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            onSubmitted: (_) => _saving ? null : _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('あとで', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B46C1),
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
