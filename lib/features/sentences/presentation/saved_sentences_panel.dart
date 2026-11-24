import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_library.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';

/// Side panel listing the sentences saved on this computer. Clicking one
/// calls [onPlay] with it.
class SavedSentencesPanel extends ConsumerWidget {
  const SavedSentencesPanel({
    super.key,
    required this.onPlay,
    required this.onClose,
  });

  final void Function(LocalSentence sentence) onPlay;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedSentencesProvider);
    return Material(
      color: AppColors.surface,
      child: Column(
        children: [
          _Header(count: saved.value?.length, onClose: onClose),
          Expanded(
            child: saved.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not read the list: $error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.outline),
                      itemBuilder: (context, index) =>
                          _Tile(sentence: items[index], onPlay: onPlay),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.count, required this.onClose});

  final int? count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == null ? 'Saved sentences' : 'Saved sentences · $count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentSoft,
              ),
            ),
          ),
          if (Platform.isMacOS)
            IconButton(
              tooltip: 'Show the folder in Finder',
              icon: const Icon(Icons.folder_open_rounded),
              onPressed: () => Process.run('open', [
                ref.read(sentenceLibraryProvider).folder,
              ]),
            ),
          IconButton(
            tooltip: 'Close (Esc)',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmarks_outlined, size: 40, color: Colors.white38),
            SizedBox(height: 12),
            Text('Nothing saved yet'),
            SizedBox(height: 4),
            Text(
              'Click a word in the subtitles, then press Save. '
              'Saving to this computer is chosen in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.sentence, required this.onPlay});

  final LocalSentence sentence;
  final void Function(LocalSentence sentence) onPlay;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete this sentence?'),
        content: Text(
          sentence.hasVideo
              ? 'The sentence and its video fragment will be removed from '
                    'this computer.'
              : 'The sentence will be removed from this computer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(savedSentencesProvider.notifier).remove(sentence);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      _date(sentence.savedAt),
      ?sentence.showName,
      if (!sentence.hasVideo) 'no video',
    ].join(' · ');
    return ListTile(
      key: ValueKey('saved-${sentence.id}'),
      onTap: sentence.hasVideo ? () => onPlay(sentence) : null,
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 4, 4),
      leading: Icon(
        sentence.hasVideo
            ? Icons.play_circle_outline_rounded
            : Icons.videocam_off_outlined,
        color: sentence.hasVideo ? AppColors.accent : Colors.white30,
      ),
      title: Text(
        sentence.text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, height: 1.35),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ),
      trailing: IconButton(
        tooltip: 'Delete',
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        onPressed: () => _delete(context, ref),
      ),
    );
  }
}

String _date(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
