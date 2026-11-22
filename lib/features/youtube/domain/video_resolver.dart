import 'dart:async';

/// A video made playable: files on disk that the player can open.
class ResolvedVideo {
  const ResolvedVideo({
    required this.title,
    required this.videoPath,
    this.subtitlePath,
  });

  final String title;
  final String videoPath;

  /// English subtitles as an .srt file, or null when the video has none.
  final String? subtitlePath;
}

enum ResolveStage { preparing, downloading }

class ResolveProgress {
  const ResolveProgress(this.stage, {this.fraction, this.title});

  final ResolveStage stage;

  /// 0..1 while downloading, null when unknown.
  final double? fraction;
  final String? title;
}

enum VideoResolveError {
  invalidUrl,
  toolMissing,
  unavailable,
  cancelled,
  failed,
}

class VideoResolveException implements Exception {
  const VideoResolveException(this.error, this.message);

  final VideoResolveError error;
  final String message;

  @override
  String toString() => 'VideoResolveException($error): $message';
}

/// Lets the user abort a running [VideoResolver.resolve].
class Cancellation {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Turns a link into local files the player can open. The only implementation
/// lives in the data layer, so the download tool can be swapped.
abstract interface class VideoResolver {
  /// Throws [VideoResolveException] on failure.
  Future<ResolvedVideo> resolve(
    String url, {
    void Function(ResolveProgress progress)? onProgress,
    Cancellation? cancellation,
  });
}
