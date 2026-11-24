import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/duration_format.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/track_menus.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';
import 'package:learner_video_player/features/settings/presentation/native_language_menu.dart';

const _timeStyle = TextStyle(
  fontSize: 12,
  color: Colors.white70,
  fontFeatures: [FontFeature.tabularFigures()],
);

const seekStep = Duration(seconds: 10);

/// Floating "glass" control bar shown over the video.
class PlayerControls extends ConsumerWidget {
  const PlayerControls({
    super.key,
    required this.onOpenVideo,
    required this.onLoadSubtitles,
    required this.onOpenUrl,
    required this.onOpenSettings,
    required this.onToggleSaved,
  });

  final VoidCallback onOpenVideo;
  final VoidCallback onLoadSubtitles;
  final VoidCallback onOpenUrl;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.read(playerGatewayProvider);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final playing = ref.watch(playingProvider).value ?? false;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(formatDuration(position), style: _timeStyle),
                  Expanded(
                    child: Slider(
                      value: position.inMilliseconds.clamp(0, maxMs).toDouble(),
                      max: maxMs.toDouble(),
                      onChanged: (ms) =>
                          gateway.seek(Duration(milliseconds: ms.round())),
                    ),
                  ),
                  Text(formatDuration(duration), style: _timeStyle),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Open video',
                    icon: const Icon(Icons.folder_open_rounded),
                    onPressed: onOpenVideo,
                  ),
                  IconButton(
                    tooltip: 'Open YouTube link',
                    icon: const Icon(Icons.link_rounded),
                    onPressed: onOpenUrl,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Previous sentence (Shift+←)',
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => gateway.seekToSentence(next: false),
                  ),
                  IconButton(
                    tooltip: 'Back 10 s (←)',
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () => gateway.seekBy(seekStep * -1),
                  ),
                  IconButton.filled(
                    tooltip: playing ? 'Pause (Space)' : 'Play (Space)',
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    onPressed: gateway.togglePlay,
                  ),
                  IconButton(
                    tooltip: 'Forward 10 s (→)',
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () => gateway.seekBy(seekStep),
                  ),
                  IconButton(
                    tooltip: 'Next sentence (Shift+→)',
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => gateway.seekToSentence(next: true),
                  ),
                  const Spacer(),
                  const AudioTrackMenu(),
                  SubtitleMenu(onLoadFile: onLoadSubtitles),
                  const NativeLanguageMenu(),
                  IconButton(
                    tooltip: 'Saved sentences',
                    icon: Icon(
                      ref.watch(savedPanelOpenProvider)
                          ? Icons.bookmarks_rounded
                          : Icons.bookmarks_outlined,
                    ),
                    onPressed: onToggleSaved,
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
