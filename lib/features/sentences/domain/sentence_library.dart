import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';

/// A sentence kept on this computer.
class LocalSentence {
  const LocalSentence({
    required this.id,
    required this.text,
    required this.savedAt,
    this.showName,
    this.videoPath,
    this.subtitlePath,
  });

  final int id;
  final String text;
  final DateTime savedAt;
  final String? showName;

  /// The saved .mp4 fragment, or null when the sentence has no video.
  final String? videoPath;

  /// An .srt holding just this sentence, to play [videoPath] with subtitles.
  final String? subtitlePath;

  bool get hasVideo => videoPath != null;
}

/// The list of sentences saved on this computer. The only implementation
/// lives in the data layer.
abstract interface class SentenceLibrary {
  /// The folder holding the saved files.
  String get folder;

  /// Stores [text]. When [clip] is given it is copied into the library, so
  /// the caller may discard it afterwards; [clipDuration] is how long it is.
  Future<LocalSentence> add({
    required String text,
    String? showName,
    Clip? clip,
    Duration? clipDuration,
  });

  /// All sentences, newest first.
  Future<List<LocalSentence>> all();

  /// Deletes the sentence and its files.
  Future<void> remove(int id);
}
