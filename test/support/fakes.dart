import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';
import 'package:learner_video_player/features/settings/domain/settings_repository.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

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

  @override
  Future<void> open(String path) async {}

  @override
  Future<void> seek(Duration position) async {}

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
  FakeSettings([this.nativeLanguageCode, this.translationPanelWidth]);

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
