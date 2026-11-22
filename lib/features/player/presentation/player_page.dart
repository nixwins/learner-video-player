import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/media_types.dart';
import 'package:learner_video_player/features/player/presentation/player_controls.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/subtitle_overlay.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _hasVideo = false;

  /// Single entry point for files from the picker and from drag-and-drop.
  Future<void> _handlePath(String path) async {
    final gateway = ref.read(playerGatewayProvider);
    switch (classifyMedia(path)) {
      case MediaKind.video:
        await gateway.open(path);
        if (mounted) setState(() => _hasVideo = true);
      case MediaKind.subtitle:
        await gateway.addExternalSubtitle(path);
      case MediaKind.unsupported:
        break;
    }
  }

  Future<void> _pick(XTypeGroup group) async {
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file != null) await _handlePath(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final gateway = ref.read(playerGatewayProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): gateway.togglePlay,
        },
        child: Focus(
          autofocus: true,
          child: DropTarget(
            onDragDone: (details) {
              if (details.files.isNotEmpty) {
                _handlePath(details.files.first.path);
              }
            },
            child: Stack(
              children: [
                Positioned.fill(child: gateway.buildVideoSurface()),
                if (!_hasVideo)
                  const Center(
                    child: Text(
                      'Drop a video here (mp4, mov, avi) or press Open',
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: const SubtitleOverlay(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PlayerControls(
                    onOpenVideo: () => _pick(videoTypeGroup),
                    onLoadSubtitles: () => _pick(subtitleTypeGroup),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
