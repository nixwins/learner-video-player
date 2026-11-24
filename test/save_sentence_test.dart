import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/player/domain/video_source.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/save_sentence.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

import 'support/fakes.dart';

const _credentials = FreqAppCredentials(
  baseUrl: 'https://freq.example.com',
  apiKey: 'tvs_secret',
);

const _source = VideoSource(
  path: '/videos/Friends.mp4',
  title: 'Friends',
  audioStreamIndex: 1,
);

const _cue = SubtitleCue(
  text: "I don't know what you mean.",
  start: Duration(seconds: 10),
  end: Duration(seconds: 13),
);

void main() {
  late FakeSentenceRepository repository;
  late FakeClipCutter cutter;
  late FakeSentenceLibrary library;
  late SaveSentence save;

  setUp(() {
    repository = FakeSentenceRepository();
    cutter = FakeClipCutter();
    library = FakeSentenceLibrary();
    save = SaveSentence(
      repository: repository,
      cutter: cutter,
      library: library,
    );
  });

  Future<SavedSentence> run({
    SubtitleCue cue = _cue,
    VideoSource? source = _source,
  }) => save(cue: cue, source: source, credentials: _credentials);

  test('cuts exactly the sentence and uploads it with the clip', () async {
    final saved = await run();

    expect(cutter.cuts.single.source, '/videos/Friends.mp4');
    expect(cutter.cuts.single.from, const Duration(milliseconds: 9750));
    expect(cutter.cuts.single.to, const Duration(milliseconds: 13300));
    expect(cutter.cuts.single.audio, 1);

    final (upload, credentials) = repository.uploads.single;
    expect(upload.sentence, "I don't know what you mean.");
    expect(upload.tvShowName, 'Friends');
    expect(upload.videoPath, '/tmp/clip.mp4');
    expect(credentials.apiKey, 'tvs_secret');
    expect(saved.withVideo, isTrue);
  });

  test('removes the temporary clip after a successful upload', () async {
    await run();
    expect(cutter.discarded, 1);
  });

  test('removes the temporary clip when the upload fails', () async {
    repository.failure = const SentenceSaveException(SaveError.server, 'boom');
    await expectLater(run(), throwsA(isA<SentenceSaveException>()));
    expect(cutter.discarded, 1);
  });

  test('saves the text alone when the timing is unknown', () async {
    final saved = await run(cue: const SubtitleCue(text: 'Hello there'));

    expect(cutter.cuts, isEmpty);
    expect(repository.uploads.single.$1.videoPath, isNull);
    expect(saved.withVideo, isFalse);
  });

  test('saves the text alone when no video is open', () async {
    final saved = await run(source: null);

    expect(cutter.cuts, isEmpty);
    expect(repository.uploads.single.$1.tvShowName, isNull);
    expect(saved.withVideo, isFalse);
  });

  test('refuses an empty sentence', () async {
    await expectLater(
      run(cue: const SubtitleCue(text: '   ')),
      throwsA(
        isA<SentenceSaveException>().having(
          (e) => e.error,
          'error',
          SaveError.invalid,
        ),
      ),
    );
    expect(repository.uploads, isEmpty);
  });

  test('refuses a sentence over the 1000 character limit', () async {
    await expectLater(
      run(cue: SubtitleCue(text: 'a' * 1001)),
      throwsA(
        isA<SentenceSaveException>().having(
          (e) => e.error,
          'error',
          SaveError.invalid,
        ),
      ),
    );
    expect(cutter.cuts, isEmpty);
    expect(repository.uploads, isEmpty);
  });

  test('accepts a sentence of exactly 1000 characters', () async {
    await run(cue: SubtitleCue(text: 'a' * 1000));
    expect(repository.uploads, hasLength(1));
  });

  test('does not upload a clip over 100 MB', () async {
    cutter.bytes = maxVideoBytes + 1;

    await expectLater(
      run(),
      throwsA(
        isA<SentenceSaveException>().having(
          (e) => e.error,
          'error',
          SaveError.tooLarge,
        ),
      ),
    );
    expect(repository.uploads, isEmpty);
    expect(cutter.discarded, 1);
  });

  test('reports a cutting failure and uploads nothing', () async {
    cutter.failure = const ClipException('ffmpeg is not installed');

    await expectLater(
      run(),
      throwsA(
        isA<SentenceSaveException>()
            .having((e) => e.error, 'error', SaveError.clip)
            .having((e) => e.message, 'message', 'ffmpeg is not installed'),
      ),
    );
    expect(repository.uploads, isEmpty);
  });

  test('cuts the show name to 200 characters', () async {
    await run(
      source: VideoSource(path: '/v.mp4', title: 'x' * 250),
    );
    expect(repository.uploads.single.$1.tvShowName, 'x' * 200);
  });

  test('a blank title sends no show name', () async {
    await run(
      source: const VideoSource(path: '/v.mp4', title: '  '),
    );
    expect(repository.uploads.single.$1.tvShowName, isNull);
  });

  group('saving on this computer', () {
    Future<SavedSentence> runLocal({
      SubtitleCue cue = _cue,
      VideoSource? source = _source,
    }) => save.saveLocally(cue: cue, source: source);

    test('keeps the sentence with its clip and does not upload', () async {
      final saved = await runLocal();

      final stored = library.added.single;
      expect(stored.text, "I don't know what you mean.");
      expect(stored.showName, 'Friends');
      expect(stored.hasVideo, isTrue);
      expect(saved.withVideo, isTrue);
      expect(repository.uploads, isEmpty);
      expect(cutter.cuts.single.from, const Duration(milliseconds: 9750));
      expect(cutter.cuts.single.to, const Duration(milliseconds: 13300));
    });

    test('removes the temporary clip afterwards', () async {
      await runLocal();
      expect(cutter.discarded, 1);
    });

    test('saves the text alone when the timing is unknown', () async {
      final saved = await runLocal(cue: const SubtitleCue(text: 'Hello'));

      expect(cutter.cuts, isEmpty);
      expect(library.added.single.hasVideo, isFalse);
      expect(saved.withVideo, isFalse);
    });

    test('a failing disk is reported as a storage error', () async {
      library.failure = const FileSystemException('disk full');

      await expectLater(
        runLocal(),
        throwsA(
          isA<SentenceSaveException>().having(
            (e) => e.error,
            'error',
            SaveError.storage,
          ),
        ),
      );
      expect(cutter.discarded, 1);
    });

    test('a cutting problem is reported and nothing is stored', () async {
      cutter.failure = const ClipException('ffmpeg is not installed');

      await expectLater(
        runLocal(),
        throwsA(
          isA<SentenceSaveException>().having(
            (e) => e.error,
            'error',
            SaveError.clip,
          ),
        ),
      );
      expect(library.added, isEmpty);
    });
  });
}
