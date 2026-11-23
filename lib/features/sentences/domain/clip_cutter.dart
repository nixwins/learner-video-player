/// A short video file made for upload. Call [discard] when done with it.
class Clip {
  const Clip({required this.path, required this.bytes, required this.discard});

  final String path;
  final int bytes;
  final Future<void> Function() discard;
}

class ClipException implements Exception {
  const ClipException(this.message);

  final String message;

  @override
  String toString() => 'ClipException: $message';
}

/// Cuts a fragment out of a video as an .mp4. The only implementation lives
/// in the data layer, so the cutting tool can be swapped.
abstract interface class ClipCutter {
  /// Throws [ClipException] on failure.
  Future<Clip> cut({
    required String sourcePath,
    required Duration from,
    required Duration to,
    int? audioStreamIndex,
  });
}
