import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';
import 'package:learner_video_player/features/player/domain/video_source.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_library.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';
import 'package:learner_video_player/features/settings/domain/settings_repository.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';

class FakeTranslationLauncher implements TranslationLauncher {
  final opened = <Uri>[];
  final _current = ValueNotifier<Uri?>(null);
  final _loadState = ValueNotifier(TranslationLoadState.ready);

  @override
  ValueListenable<Uri?> get current => _current;

  @override
  ValueListenable<TranslationLoadState> get loadState => _loadState;

  @override
  Future<void> open(Uri uri) async {
    opened.add(uri);
    _current.value = uri;
  }

  @override
  Future<void> reload() async {}

  @override
  void close() => _current.value = null;

  @override
  Widget buildView() => const SizedBox(key: Key('fake-web-view'));
}

class FakePlayerGateway implements PlayerGateway {
  int pauseCalls = 0;
  int togglePlayCalls = 0;
  final playedRanges = <(Duration, Duration)>[];

  SubtitleCue? cue = SubtitleCue.fromRaw(
    'I know the government',
    start: const Duration(seconds: 10),
    end: const Duration(seconds: 13),
  );

  @override
  Future<SubtitleCue?> currentSubtitleCue() async => cue;

  @override
  Future<void> playRange(Duration start, Duration end) async =>
      playedRanges.add((start, end));

  @override
  Widget buildVideoSurface() => const SizedBox.expand();

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> togglePlay() async => togglePlayCalls++;

  final opened = <(String, String?)>[];
  final openedTitles = <String?>[];
  VideoSource? source = const VideoSource(
    path: '/videos/Friends S01E02.mp4',
    title: 'Friends S01E02',
    audioStreamIndex: 1,
  );

  @override
  VideoSource? currentSource() => source;

  @override
  Future<void> open(String path, {String? subtitlePath, String? title}) async {
    opened.add((path, subtitlePath));
    openedTitles.add(title);
  }

  @override
  Future<void> seek(Duration position) async {}

  final seekDeltas = <Duration>[];
  final sentenceSeeks = <bool>[];

  @override
  Future<void> seekBy(Duration delta) async => seekDeltas.add(delta);

  @override
  Future<void> seekToSentence({required bool next}) async =>
      sentenceSeeks.add(next);

  @override
  Future<void> selectAudio(String id) async {}

  @override
  Future<void> selectSubtitle(String? id) async {}

  @override
  Future<void> addExternalSubtitle(String path) async {}

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Stream<Duration> get position => const Stream.empty();

  @override
  Stream<Duration> get duration => const Stream.empty();

  @override
  Stream<List<Choice>> get audioTracks => const Stream.empty();

  @override
  Stream<List<Choice>> get subtitleTracks => const Stream.empty();

  @override
  Stream<String?> get selectedAudioId => const Stream.empty();

  @override
  Stream<String?> get selectedSubtitleId => const Stream.empty();

  @override
  Stream<String> get subtitleText => Stream.value('I know the government');

  @override
  Future<void> dispose() async {}
}

class FakeSettings implements SettingsRepository {
  FakeSettings([
    this.nativeLanguageCode,
    this.translationPanelWidth,
    this.freqAppServer,
    this.freqAppApiKey,
  ]);

  @override
  String? saveDestination;

  @override
  Future<void> saveSaveDestination(String destination) async =>
      saveDestination = destination;

  @override
  String? freqAppServer;

  @override
  String? freqAppApiKey;

  @override
  Future<void> saveFreqAppServer(String server) async =>
      freqAppServer = server.isEmpty ? null : server;

  @override
  Future<void> saveFreqAppApiKey(String apiKey) async =>
      freqAppApiKey = apiKey.isEmpty ? null : apiKey;

  @override
  String? nativeLanguageCode;

  @override
  double? translationPanelWidth;

  @override
  Future<void> saveNativeLanguageCode(String code) async =>
      nativeLanguageCode = code;

  @override
  Future<void> saveTranslationPanelWidth(double width) async =>
      translationPanelWidth = width;
}

class FakeVideoResolver implements VideoResolver {
  final requested = <String>[];
  ResolvedVideo? result = const ResolvedVideo(
    title: 'Me at the zoo',
    videoPath: '/tmp/video.mp4',
    subtitlePath: '/tmp/video.en.srt',
  );
  VideoResolveException? failure;

  /// When set, resolve waits for it, so tests can look at the loading state.
  Completer<void>? gate;

  @override
  Future<ResolvedVideo> resolve(
    String url, {
    void Function(ResolveProgress progress)? onProgress,
    Cancellation? cancellation,
  }) async {
    requested.add(url);
    onProgress?.call(
      const ResolveProgress(
        ResolveStage.downloading,
        fraction: 0.5,
        title: 'Me at the zoo',
      ),
    );
    final gate = this.gate;
    if (gate != null) {
      await Future.any([gate.future, ?cancellation?.whenCancelled]);
      if (cancellation?.isCancelled ?? false) {
        throw const VideoResolveException(
          VideoResolveError.cancelled,
          'Cancelled.',
        );
      }
    }
    final failure = this.failure;
    if (failure != null) throw failure;
    return result!;
  }
}

class FakeSentenceRepository implements SentenceRepository {
  final uploads = <(SentenceUpload, FreqAppCredentials)>[];
  SentenceSaveException? failure;

  /// When set, save waits for it so tests can look at the "saving" state.
  Completer<void>? gate;

  @override
  Future<SavedSentence> save(
    SentenceUpload upload,
    FreqAppCredentials credentials,
  ) async {
    uploads.add((upload, credentials));
    await gate?.future;
    final failure = this.failure;
    if (failure != null) throw failure;
    return SavedSentence(id: 'id-1', withVideo: upload.videoPath != null);
  }
}

class FakeClipCutter implements ClipCutter {
  final cuts = <({String source, Duration from, Duration to, int? audio})>[];
  int discarded = 0;
  int bytes = 1024;
  ClipException? failure;

  @override
  Future<Clip> cut({
    required String sourcePath,
    required Duration from,
    required Duration to,
    int? audioStreamIndex,
  }) async {
    cuts.add((source: sourcePath, from: from, to: to, audio: audioStreamIndex));
    final failure = this.failure;
    if (failure != null) throw failure;
    return Clip(
      path: '/tmp/clip.mp4',
      bytes: bytes,
      discard: () async => discarded++,
    );
  }
}

class FakeSentenceLibrary implements SentenceLibrary {
  final added = <LocalSentence>[];
  final removed = <int>[];
  Object? failure;
  var _nextId = 1;

  @override
  String get folder => '/library';

  @override
  Future<LocalSentence> add({
    required String text,
    String? showName,
    Clip? clip,
    Duration? clipDuration,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    final id = _nextId++;
    final sentence = LocalSentence(
      id: id,
      text: text,
      showName: showName,
      savedAt: DateTime(2026, 11, 24),
      videoPath: clip == null ? null : '/library/sentence-$id.mp4',
      subtitlePath: clip == null ? null : '/library/sentence-$id.srt',
    );
    added.add(sentence);
    return sentence;
  }

  @override
  Future<List<LocalSentence>> all() async => [
    for (final sentence in added.reversed)
      if (!removed.contains(sentence.id)) sentence,
  ];

  @override
  Future<void> remove(int id) async => removed.add(id);
}
