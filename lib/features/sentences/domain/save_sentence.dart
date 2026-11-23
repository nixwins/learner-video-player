import 'package:learner_video_player/features/player/domain/video_source.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

/// Use case: save a subtitle sentence together with just its video fragment.
///
/// When the cue's timing is unknown the sentence is saved without a video;
/// [SavedSentence.withVideo] tells the caller.
class SaveSentence {
  const SaveSentence({required this.repository, required this.cutter});

  final SentenceRepository repository;
  final ClipCutter cutter;

  Future<SavedSentence> call({
    required SubtitleCue cue,
    required VideoSource? source,
    required FreqAppCredentials credentials,
  }) async {
    final text = cue.text.trim();
    if (text.isEmpty) {
      throw const SentenceSaveException(
        SaveError.invalid,
        'There is no sentence to save.',
      );
    }
    if (text.length > maxSentenceLength) {
      throw SentenceSaveException(
        SaveError.invalid,
        'The sentence is too long (${text.length} of $maxSentenceLength '
        'characters).',
      );
    }

    Clip? clip;
    try {
      if (cue.canReplay && source != null) {
        clip = await _cut(cue, source);
        if (clip.bytes > maxVideoBytes) {
          throw const SentenceSaveException(
            SaveError.tooLarge,
            'The video fragment is larger than 100 MB.',
          );
        }
      }
      return await repository.save(
        SentenceUpload(
          sentence: text,
          tvShowName: _showName(source),
          videoPath: clip?.path,
        ),
        credentials,
      );
    } finally {
      await clip?.discard();
    }
  }

  Future<Clip> _cut(SubtitleCue cue, VideoSource source) async {
    try {
      return await cutter.cut(
        sourcePath: source.path,
        from: cue.clipFrom,
        to: cue.clipTo,
        audioStreamIndex: source.audioStreamIndex,
      );
    } on ClipException catch (e) {
      throw SentenceSaveException(SaveError.clip, e.message);
    }
  }

  String? _showName(VideoSource? source) {
    final title = source?.title.trim() ?? '';
    if (title.isEmpty) return null;
    return String.fromCharCodes(title.runes.take(maxShowNameLength));
  }
}
