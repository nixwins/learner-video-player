/// The video that is open in the player.
class VideoSource {
  const VideoSource({
    required this.path,
    required this.title,
    this.audioStreamIndex,
  });

  final String path;

  /// A human-readable name: the YouTube title or the file name.
  final String title;

  /// Zero-based position of the selected audio track among the audio tracks of
  /// the file, or null when the player did not pick one.
  final int? audioStreamIndex;
}
