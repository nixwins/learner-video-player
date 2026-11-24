import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';

const maxSentenceLength = 1000;
const maxShowNameLength = 200;
const maxVideoBytes = 100 * 1024 * 1024;

class SentenceUpload {
  const SentenceUpload({
    required this.sentence,
    this.tvShowName,
    this.videoPath,
  });

  final String sentence;
  final String? tvShowName;

  /// An .mp4 file to attach, or null to save the text alone.
  final String? videoPath;
}

class SavedSentence {
  const SavedSentence({required this.id, required this.withVideo});

  final String id;
  final bool withVideo;
}

enum SaveError {
  notConfigured,
  invalid,
  unauthorized,
  tooLarge,
  rateLimited,
  clip,
  network,

  /// Writing to the local list or its folder failed.
  storage,

  /// The request may have reached the server; saving again could duplicate.
  uncertain,
  server,
}

class SentenceSaveException implements Exception {
  const SentenceSaveException(this.error, this.message);

  final SaveError error;
  final String message;

  @override
  String toString() => 'SentenceSaveException($error): $message';
}

/// Stores sentences on the server. The only implementation lives in the data
/// layer. It never retries by itself: a repeat can create a duplicate.
abstract interface class SentenceRepository {
  /// Throws [SentenceSaveException] on failure.
  Future<SavedSentence> save(
    SentenceUpload upload,
    FreqAppCredentials credentials,
  );
}
