import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/core/widgets/option_menu_button.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';

/// Audio track picker; hidden when the video has fewer than two tracks.
class AudioTrackMenu extends ConsumerWidget {
  const AudioTrackMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(audioTracksProvider).value ?? const [];
    if (tracks.length < 2) return const SizedBox.shrink();
    return OptionMenuButton(
      icon: Icons.music_note_rounded,
      tooltip: 'Audio track',
      options: tracks,
      selectedId: ref.watch(selectedAudioIdProvider).value,
      onSelected: ref.read(playerGatewayProvider).selectAudio,
    );
  }
}

const _offId = '__off__';
const _loadFileId = '__load_file__';

/// Subtitle picker: off, embedded/external tracks, and "load file…".
class SubtitleMenu extends ConsumerWidget {
  const SubtitleMenu({super.key, required this.onLoadFile});

  final VoidCallback onLoadFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(subtitleTracksProvider).value ?? const [];
    return OptionMenuButton(
      icon: Icons.closed_caption_rounded,
      tooltip: 'Subtitles',
      options: [
        const Choice(id: _offId, label: 'Off'),
        ...tracks,
        const Choice(id: _loadFileId, label: 'Load file…'),
      ],
      selectedId: ref.watch(selectedSubtitleIdProvider).value ?? _offId,
      onSelected: (id) {
        if (id == _loadFileId) {
          onLoadFile();
        } else {
          ref
              .read(playerGatewayProvider)
              .selectSubtitle(id == _offId ? null : id);
        }
      },
    );
  }
}
