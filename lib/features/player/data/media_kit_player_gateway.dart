import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/core/media_types.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';
import 'package:learner_video_player/features/player/domain/video_source.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// The only place that knows about media_kit (libmpv).
class MediaKitPlayerGateway implements PlayerGateway {
  final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  /// media_kit exposes pseudo tracks 'auto' and 'no'; they are not choices.
  static const _pseudoTrackIds = {'auto', 'no'};

  @override
  Widget buildVideoSurface() => Video(
    controller: _controller,
    controls: NoVideoControls,
    // We draw subtitles ourselves so that words are clickable.
    subtitleViewConfiguration: const SubtitleViewConfiguration(visible: false),
  );

  /// How early before a cue's end the player is paused, to compensate for the
  /// coarse position updates.
  static const _endMargin = Duration(milliseconds: 100);

  StreamSubscription<Duration>? _rangeEnd;

  /// How long to wait for a freshly opened file before adding its subtitles.
  static const _loadTimeout = Duration(seconds: 5);

  VideoSource? _source;

  @override
  VideoSource? currentSource() {
    final source = _source;
    if (source == null) return null;
    // mpv numbers audio tracks from 1; ffmpeg counts audio streams from 0.
    final number = int.tryParse(_player.state.track.audio.id);
    return VideoSource(
      path: source.path,
      title: source.title,
      audioStreamIndex: number == null ? null : number - 1,
    );
  }

  @override
  Future<void> open(String path, {String? subtitlePath, String? title}) async {
    _cancelRange();
    _source = VideoSource(path: path, title: title ?? titleFromPath(path));
    // mpv rejects "add subtitle" until a file is loaded; a new duration is the
    // earliest signal that it is. Listen before opening so it is not missed.
    final loaded = subtitlePath == null
        ? null
        : _player.stream.duration
              .firstWhere((duration) => duration > Duration.zero)
              .timeout(_loadTimeout, onTimeout: () => Duration.zero);
    await _player.open(Media(path));
    if (loaded != null) {
      await loaded;
      await addExternalSubtitle(subtitlePath!);
    }
  }

  @override
  Future<void> togglePlay() {
    _cancelRange();
    return _player.playOrPause();
  }

  @override
  Future<void> pause() {
    _cancelRange();
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) {
    _cancelRange();
    return _player.seek(position);
  }

  @override
  Future<void> seekBy(Duration delta) {
    final state = _player.state;
    final target = state.position + delta;
    final end = state.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (end > Duration.zero && target > end ? end : target);
    return seek(clamped);
  }

  @override
  Future<void> seekToSentence({required bool next}) async {
    _cancelRange();
    try {
      final platform = _player.platform as dynamic;
      await platform.command(['sub-seek', next ? '1' : '-1']);
    } catch (_) {}
  }

  @override
  Future<void> playRange(Duration start, Duration end) async {
    _cancelRange();
    await _player.seek(start);
    await _player.play();
    _rangeEnd = _player.stream.position.listen((position) {
      if (position >= end - _endMargin) {
        _cancelRange();
        _player.pause();
      }
    });
  }

  void _cancelRange() {
    _rangeEnd?.cancel();
    _rangeEnd = null;
  }

  @override
  Future<SubtitleCue?> currentSubtitleCue() async {
    final raw = _player.state.subtitle.join('\n');
    final cue = SubtitleCue.fromRaw(
      raw,
      start: await _readSeconds('sub-start'),
      end: await _readSeconds('sub-end'),
    );
    return cue.text.isEmpty ? null : cue;
  }

  /// Reads an mpv time property (seconds). It is empty when there is no
  /// subtitle, and unavailable for image-based or unsupported engines.
  Future<Duration?> _readSeconds(String property) async {
    try {
      final platform = _player.platform as dynamic;
      final value = await platform.getProperty(property) as String;
      final seconds = double.tryParse(value);
      if (seconds == null) return null;
      return Duration(microseconds: (seconds * 1e6).round());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> selectAudio(String id) => _player.setAudioTrack(
    _player.state.tracks.audio.firstWhere((track) => track.id == id),
  );

  @override
  Future<void> selectSubtitle(String? id) => _player.setSubtitleTrack(
    id == null
        ? SubtitleTrack.no()
        : _player.state.tracks.subtitle.firstWhere((track) => track.id == id),
  );

  @override
  Future<void> addExternalSubtitle(String path) =>
      _player.setSubtitleTrack(SubtitleTrack.uri(path));

  @override
  Stream<bool> get playing =>
      _withInitial(_player.state.playing, _player.stream.playing);

  @override
  Stream<Duration> get position =>
      _withInitial(_player.state.position, _player.stream.position);

  @override
  Stream<Duration> get duration =>
      _withInitial(_player.state.duration, _player.stream.duration);

  @override
  Stream<List<Choice>> get audioTracks =>
      _withInitial(_player.state.tracks, _player.stream.tracks).map(
        (tracks) =>
            _choices(tracks.audio.map((t) => (t.id, t.title, t.language))),
      );

  @override
  Stream<List<Choice>> get subtitleTracks =>
      _withInitial(_player.state.tracks, _player.stream.tracks).map(
        (tracks) =>
            _choices(tracks.subtitle.map((t) => (t.id, t.title, t.language))),
      );

  @override
  Stream<String?> get selectedAudioId => _withInitial(
    _player.state.track,
    _player.stream.track,
  ).map((track) => _realId(track.audio.id)).distinct();

  @override
  Stream<String?> get selectedSubtitleId => _withInitial(
    _player.state.track,
    _player.stream.track,
  ).map((track) => _realId(track.subtitle.id)).distinct();

  @override
  Stream<String> get subtitleText => _withInitial(
    _player.state.subtitle,
    _player.stream.subtitle,
  ).map((lines) => lines.join('\n'));

  @override
  Future<void> dispose() {
    _cancelRange();
    return _player.dispose();
  }

  /// media_kit streams only emit changes; start with the current value so
  /// listeners get data immediately.
  Stream<T> _withInitial<T>(T initial, Stream<T> updates) async* {
    yield initial;
    yield* updates;
  }

  String? _realId(String id) => _pseudoTrackIds.contains(id) ? null : id;

  List<Choice> _choices(Iterable<(String, String?, String?)> raw) {
    final real = raw.where((t) => !_pseudoTrackIds.contains(t.$1)).toList();
    return [
      for (final (index, track) in real.indexed)
        Choice(id: track.$1, label: _label(index + 1, track.$2, track.$3)),
    ];
  }

  String _label(int number, String? title, String? language) {
    final parts = [
      title,
      language,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? 'Track $number' : parts.join(' · ');
  }
}
