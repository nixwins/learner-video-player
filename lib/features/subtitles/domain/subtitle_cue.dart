import 'package:learner_video_player/features/subtitles/domain/subtitle_tokenizer.dart';

/// Playback starts slightly before the cue so its first word is not cut off.
const _replayLeadIn = Duration(milliseconds: 250);

/// One subtitle sentence as shown on screen, with its place in the video.
/// [start] and [end] are null when the engine cannot tell.
class SubtitleCue {
  const SubtitleCue({required this.text, this.start, this.end});

  /// Builds a cue from raw subtitle lines: markup is removed and the lines
  /// are joined into one sentence.
  factory SubtitleCue.fromRaw(String raw, {Duration? start, Duration? end}) {
    final lines = raw
        .split('\n')
        .map((line) => tokenizeSubtitle(line).map((t) => t.text).join())
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return SubtitleCue(text: lines.join(' '), start: start, end: end);
  }

  final String text;
  final Duration? start;
  final Duration? end;

  bool get canReplay {
    final start = this.start;
    final end = this.end;
    return start != null && end != null && end > start;
  }

  /// Where "play again" begins. Only meaningful when [canReplay] is true.
  Duration get replayFrom {
    final from = start! - _replayLeadIn;
    return from.isNegative ? Duration.zero : from;
  }
}
