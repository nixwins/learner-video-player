import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';

/// Opens the settings. Completes with true when the user saved changes.
Future<bool> showSettingsDialog(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => const SettingsDialog(),
  );
  return saved ?? false;
}

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late final TextEditingController _server;
  late final TextEditingController _apiKey;
  bool _showKey = false;
  String? _serverError;
  String? _keyError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(freqAppSettingsProvider);
    _server = TextEditingController(text: settings.server);
    _apiKey = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _server.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final serverOk = normalizeServerAddress(_server.text) != null;
    final keyOk = _apiKey.text.trim().isNotEmpty;
    setState(() {
      _serverError = serverOk
          ? null
          : 'Enter an address like https://example.com';
      _keyError = keyOk ? null : 'Enter the API key';
    });
    if (!serverOk || !keyOk) return;

    await ref
        .read(freqAppSettingsProvider.notifier)
        .save(server: _server.text, apiKey: _apiKey.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      title: const Text('Settings'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FreqApp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSoft,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _server,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Server address',
                hintText: 'https://example.com',
                prefixIcon: const Icon(Icons.dns_outlined),
                border: const OutlineInputBorder(),
                errorText: _serverError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKey,
              obscureText: !_showKey,
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'API key',
                hintText: 'tvs_…',
                prefixIcon: const Icon(Icons.key_rounded),
                border: const OutlineInputBorder(),
                errorText: _keyError,
                suffixIcon: IconButton(
                  tooltip: _showKey ? 'Hide key' : 'Show key',
                  icon: Icon(
                    _showKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The key is created by an admin in Settings → API keys and is '
              'shown only once. To replace it, type the new one and press '
              'Save. It is kept on this computer only.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
