import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';
import 'package:learner_video_player/features/youtube/domain/youtube_url.dart';

/// Wired in `main.dart`.
final videoResolverProvider = Provider<VideoResolver>(
  (ref) => throw UnimplementedError('Override videoResolverProvider'),
);

enum YoutubeLoadStatus { idle, loading, failed }

class YoutubeLoadState {
  const YoutubeLoadState(
    this.status, {
    this.stage = ResolveStage.preparing,
    this.fraction,
    this.title,
    this.message,
  });

  const YoutubeLoadState.idle() : this(YoutubeLoadStatus.idle);

  final YoutubeLoadStatus status;
  final ResolveStage stage;
  final double? fraction;
  final String? title;
  final String? message;

  bool get isLoading => status == YoutubeLoadStatus.loading;
}

class YoutubeOpenResult {
  const YoutubeOpenResult({required this.title, required this.hasSubtitles});

  final String title;
  final bool hasSubtitles;
}

/// Downloads a YouTube video and opens it in the player.
class YoutubeLoaderNotifier extends Notifier<YoutubeLoadState> {
  Cancellation? _cancellation;

  @override
  YoutubeLoadState build() => const YoutubeLoadState.idle();

  /// Returns null when loading failed (see [state]) or was cancelled.
  Future<YoutubeOpenResult?> load(String input) async {
    if (state.isLoading) return null;
    if (youtubeVideoId(input) == null) {
      state = const YoutubeLoadState(
        YoutubeLoadStatus.failed,
        message: 'This does not look like a link to a YouTube video.',
      );
      return null;
    }

    final cancellation = _cancellation = Cancellation();
    state = const YoutubeLoadState(YoutubeLoadStatus.loading);
    try {
      final video = await ref
          .read(videoResolverProvider)
          .resolve(
            input,
            cancellation: cancellation,
            onProgress: (progress) => state = YoutubeLoadState(
              YoutubeLoadStatus.loading,
              stage: progress.stage,
              fraction: progress.fraction,
              title: progress.title,
            ),
          );
      if (cancellation.isCancelled) return _idle();
      await ref
          .read(playerGatewayProvider)
          .open(video.videoPath, subtitlePath: video.subtitlePath);
      state = const YoutubeLoadState.idle();
      return YoutubeOpenResult(
        title: video.title,
        hasSubtitles: video.subtitlePath != null,
      );
    } on VideoResolveException catch (e) {
      if (e.error == VideoResolveError.cancelled) return _idle();
      state = YoutubeLoadState(YoutubeLoadStatus.failed, message: e.message);
      return null;
    } catch (e) {
      state = YoutubeLoadState(
        YoutubeLoadStatus.failed,
        message: 'Could not open the video: $e',
      );
      return null;
    }
  }

  YoutubeOpenResult? _idle() {
    state = const YoutubeLoadState.idle();
    return null;
  }

  void cancel() => _cancellation?.cancel();

  void reset() => state = const YoutubeLoadState.idle();
}

final youtubeLoaderProvider =
    NotifierProvider<YoutubeLoaderNotifier, YoutubeLoadState>(
      YoutubeLoaderNotifier.new,
    );
