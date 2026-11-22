import 'package:flutter/widgets.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

/// What the app needs from a video engine. The only implementation lives in
/// the data layer, so the engine can be swapped without touching the UI.
///
/// Pragmatic note: [buildVideoSurface] returns a Flutter widget because the
/// engine owns its texture; everything else is plain Dart.
abstract interface class PlayerGateway {
  Widget buildVideoSurface();

  /// Opens [path]. When [subtitlePath] is given, it is loaded as the active
  /// subtitle track once the video is ready.
  Future<void> open(String path, {String? subtitlePath});
  Future<void> togglePlay();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Plays from [start] and pauses by itself when [end] is reached.
  Future<void> playRange(Duration start, Duration end);

  /// The subtitle sentence on screen right now, or null if there is none.
  Future<SubtitleCue?> currentSubtitleCue();

  Future<void> selectAudio(String id);

  /// Selects subtitle track [id]; null turns subtitles off.
  Future<void> selectSubtitle(String? id);
  Future<void> addExternalSubtitle(String path);

  Stream<bool> get playing;
  Stream<Duration> get position;
  Stream<Duration> get duration;

  Stream<List<Choice>> get audioTracks;
  Stream<List<Choice>> get subtitleTracks;
  Stream<String?> get selectedAudioId;
  Stream<String?> get selectedSubtitleId;

  /// Text of the currently displayed subtitle ('' when none).
  Stream<String> get subtitleText;

  Future<void> dispose();
}
