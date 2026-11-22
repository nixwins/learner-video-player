import 'package:flutter/material.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';
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

  @override
  Future<void> open(String path) => _player.open(Media(path));

  @override
  Future<void> togglePlay() => _player.playOrPause();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

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
  Future<void> dispose() => _player.dispose();

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
