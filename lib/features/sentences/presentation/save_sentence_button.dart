import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_dialog.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

/// "Save" button for one sentence. Without FreqApp settings it opens them
/// first, then saves.
class SaveSentenceButton extends ConsumerWidget {
  const SaveSentenceButton({super.key, required this.cue});

  final SubtitleCue cue;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    if (!ref.read(freqAppSettingsProvider).isConfigured) {
      final saved = await showSettingsDialog(context);
      if (!saved) return;
    }
    await ref.read(sentenceSaveProvider.notifier).save(cue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(sentenceSaveProvider)[cueKey(cue)] ?? SaveState.idle;
    return switch (state.status) {
      SaveStatus.saving => FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Saving…'),
      ),
      SaveStatus.saved => FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Saved'),
      ),
      SaveStatus.idle || SaveStatus.failed => FilledButton.icon(
        onPressed: () => _onPressed(context, ref),
        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
        label: const Text('Save'),
      ),
    };
  }
}

/// The result of the last save attempt of [cue]: success note or error.
class SaveSentenceStatus extends ConsumerWidget {
  const SaveSentenceStatus({super.key, required this.cue});

  final SubtitleCue cue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(sentenceSaveProvider)[cueKey(cue)] ?? SaveState.idle;
    final message = state.message;
    if (message == null) return const SizedBox.shrink();
    final failed = state.status == SaveStatus.failed;
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 12),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: failed
              ? Theme.of(context).colorScheme.error
              : Colors.greenAccent.shade100,
        ),
      ),
    );
  }
}
