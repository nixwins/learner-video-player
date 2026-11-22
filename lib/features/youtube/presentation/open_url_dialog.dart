import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';
import 'package:learner_video_player/features/youtube/domain/youtube_url.dart';
import 'package:learner_video_player/features/youtube/presentation/youtube_providers.dart';

/// Asks for a YouTube link, downloads the video and closes with the result.
Future<YoutubeOpenResult?> showOpenUrlDialog(BuildContext context) {
  return showDialog<YoutubeOpenResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const OpenUrlDialog(),
  );
}

class OpenUrlDialog extends ConsumerStatefulWidget {
  const OpenUrlDialog({super.key});

  @override
  ConsumerState<OpenUrlDialog> createState() => _OpenUrlDialogState();
}

class _OpenUrlDialogState extends ConsumerState<OpenUrlDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Providers must not change while the tree is building.
    Future.microtask(ref.read(youtubeLoaderProvider.notifier).reset);
    _prefillFromClipboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prefillFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (mounted &&
        _controller.text.isEmpty &&
        text != null &&
        youtubeVideoId(text) != null) {
      _controller.text = text;
    }
  }

  Future<void> _submit() async {
    final result = await ref
        .read(youtubeLoaderProvider.notifier)
        .load(_controller.text);
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  void _cancel() {
    final loader = ref.read(youtubeLoaderProvider.notifier);
    if (ref.read(youtubeLoaderProvider).isLoading) {
      loader.cancel();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(youtubeLoaderProvider);
    return PopScope(
      canPop: !state.isLoading,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        title: const Text('Open a YouTube link'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                enabled: !state.isLoading,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=…',
                  prefixIcon: Icon(Icons.link_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (state.isLoading) _Progress(state),
              if (state.status == YoutubeLoadStatus.failed)
                Text(
                  state.message ?? 'Something went wrong.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (state.status == YoutubeLoadStatus.idle)
                const Text(
                  'The video is downloaded once (up to 720p) together with its '
                  'English subtitles, so words stay clickable.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancel,
            child: Text(state.isLoading ? 'Cancel download' : 'Close'),
          ),
          FilledButton(
            onPressed: state.isLoading ? null : _submit,
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress(this.state);

  final YoutubeLoadState state;

  @override
  Widget build(BuildContext context) {
    final downloading = state.stage == ResolveStage.downloading;
    final percent = state.fraction == null
        ? ''
        : ' ${(state.fraction! * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          downloading
              ? 'Downloading${state.title == null ? '' : ' “${state.title}”'}$percent'
              : 'Looking up the video…',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: downloading ? state.fraction : null),
      ],
    );
  }
}
