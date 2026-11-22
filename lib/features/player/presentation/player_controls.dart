import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/duration_format.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/track_menus.dart';
import 'package:learner_video_player/features/settings/presentation/native_language_menu.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({
    super.key,
    required this.onOpenVideo,
    required this.onLoadSubtitles,
  });

  final VoidCallback onOpenVideo;
  final VoidCallback onLoadSubtitles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.read(playerGatewayProvider);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final playing = ref.watch(playingProvider).value ?? false;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(formatDuration(position)),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
                  max: maxMs.toDouble(),
                  onChanged: (ms) =>
                      gateway.seek(Duration(milliseconds: ms.round())),
                ),
              ),
              Text(formatDuration(duration)),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Open video',
                icon: const Icon(Icons.folder_open),
                onPressed: onOpenVideo,
              ),
              IconButton(
                tooltip: playing ? 'Pause' : 'Play',
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: gateway.togglePlay,
              ),
              const Spacer(),
              const AudioTrackMenu(),
              SubtitleMenu(onLoadFile: onLoadSubtitles),
              const NativeLanguageMenu(),
            ],
          ),
        ],
      ),
    );
  }
}
