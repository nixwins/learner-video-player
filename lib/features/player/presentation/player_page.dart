import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/media_types.dart';
import 'package:learner_video_player/core/panel_width.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';
import 'package:learner_video_player/features/player/presentation/player_controls.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/subtitle_overlay.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_library.dart';
import 'package:learner_video_player/features/sentences/presentation/saved_sentences_panel.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_dialog.dart';
import 'package:learner_video_player/features/translation/presentation/translation_panel.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';
import 'package:learner_video_player/features/youtube/presentation/open_url_dialog.dart';

const _controlsHideDelay = Duration(milliseconds: 2500);
const _animation = Duration(milliseconds: 200);

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  final _focusNode = FocusNode();
  Timer? _hideTimer;
  bool _hasVideo = false;
  bool _controlsVisible = true;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

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

  Future<void> _openUrl() async {
    final result = await showOpenUrlDialog(context);
    if (result == null || !mounted) return;
    setState(() => _hasVideo = true);
    if (!result.hasSubtitles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This video has no English subtitles.')),
      );
    }
  }

  Future<void> _playSaved(LocalSentence sentence) async {
    await ref
        .read(playerGatewayProvider)
        .open(
          sentence.videoPath!,
          subtitlePath: sentence.subtitlePath,
          title: sentence.showName,
        );
    if (mounted) setState(() => _hasVideo = true);
  }

  /// Shows or hides the saved list. It shares the side slot with the
  /// translation panel, so opening it closes that one.
  void _toggleSaved() {
    final open = ref.read(savedPanelOpenProvider);
    final launcher = ref.read(translationLauncherProvider);
    final translating = launcher.current.value != null;
    launcher.close();
    ref.read(savedPanelOpenProvider.notifier).set(translating || !open);
  }

  void _closePanels() {
    ref.read(translationLauncherProvider).close();
    ref.read(savedPanelOpenProvider.notifier).set(false);
  }

  void _showControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer = Timer(_controlsHideDelay, () {
      final playing = ref.read(playingProvider).value ?? false;
      if (mounted && _hasVideo && playing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onVideoTap() {
    _focusNode.requestFocus();
    if (_hasVideo) ref.read(playerGatewayProvider).togglePlay();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playingProvider, (_, playing) {
      if (playing.value ?? false) _showControls();
    });
    final gateway = ref.read(playerGatewayProvider);
    final launcher = ref.watch(translationLauncherProvider);
    final savedOpen = ref.watch(savedPanelOpenProvider);

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): gateway.togglePlay,
          const SingleActivator(LogicalKeyboardKey.escape): _closePanels,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              gateway.seekBy(seekStep * -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              gateway.seekBy(seekStep),
          const SingleActivator(
            LogicalKeyboardKey.arrowLeft,
            shift: true,
          ): () =>
              gateway.seekToSentence(next: false),
          const SingleActivator(
            LogicalKeyboardKey.arrowRight,
            shift: true,
          ): () =>
              gateway.seekToSentence(next: true),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: DropTarget(
            onDragDone: (details) {
              if (details.files.isNotEmpty) {
                _handlePath(details.files.first.path);
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) => ValueListenableBuilder<Uri?>(
                valueListenable: launcher.current,
                builder: (context, uri, _) {
                  final width = clampPanelWidth(
                    ref.watch(translationPanelWidthProvider),
                    constraints.maxWidth,
                  );
                  return Row(
                    children: [
                      Expanded(child: _buildPlayerArea(gateway)),
                      if (uri != null || savedOpen) ...[
                        _ResizeHandle(available: constraints.maxWidth),
                        SizedBox(
                          width: width,
                          child: uri != null
                              ? TranslationPanel(uri: uri)
                              : SavedSentencesPanel(
                                  onPlay: _playSaved,
                                  onClose: _closePanels,
                                ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea(PlayerGateway gateway) {
    final showControls = _controlsVisible || !_hasVideo;
    return MouseRegion(
      onHover: (_) => _showControls(),
      cursor: showControls ? MouseCursor.defer : SystemMouseCursors.none,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onVideoTap,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(child: gateway.buildVideoSurface()),
              if (!_hasVideo)
                Center(
                  child: _EmptyState(
                    onOpen: () => _pick(videoTypeGroup),
                    onOpenUrl: _openUrl,
                  ),
                ),
              AnimatedPositioned(
                duration: _animation,
                curve: Curves.easeOut,
                left: 24,
                right: 24,
                bottom: showControls ? 132 : 40,
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: SubtitleOverlay(),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: AnimatedOpacity(
                      duration: _animation,
                      opacity: showControls ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !showControls,
                        child: PlayerControls(
                          onOpenVideo: () => _pick(videoTypeGroup),
                          onLoadSubtitles: () => _pick(subtitleTypeGroup),
                          onOpenUrl: _openUrl,
                          onOpenSettings: () => showSettingsDialog(context),
                          onToggleSaved: _toggleSaved,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen, required this.onOpenUrl});

  final VoidCallback onOpen;
  final VoidCallback onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.movie_creation_outlined,
          size: 64,
          color: AppColors.accentSoft,
        ),
        const SizedBox(height: 20),
        const Text(
          'Drop a video here',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'mp4 · mkv · mov · avi   —   subtitles: drop an .srt file',
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Open video'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenUrl,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Open YouTube link'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Thin draggable divider between the player and the translation panel.
class _ResizeHandle extends ConsumerWidget {
  const _ResizeHandle({required this.available});

  final double available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(translationPanelWidthProvider.notifier);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => notifier.resize(
          clampPanelWidth(
            ref.read(translationPanelWidthProvider) - details.delta.dx,
            available,
          ),
        ),
        onHorizontalDragEnd: (_) => notifier.persist(),
        child: Container(
          width: 8,
          color: AppColors.surface,
          alignment: Alignment.center,
          child: Container(
            width: 2,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}
