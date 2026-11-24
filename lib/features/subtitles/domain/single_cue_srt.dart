/// An .srt file with one sentence shown for the whole [duration], so a saved
/// clip can be played with clickable subtitles.
String singleCueSrt(String text, Duration duration) =>
    '1\n00:00:00,000 --> ${_timestamp(duration)}\n${text.trim()}\n';

String _timestamp(Duration d) {
  String pad(int n, int width) => n.toString().padLeft(width, '0');
  return '${pad(d.inHours, 2)}:${pad(d.inMinutes.remainder(60), 2)}:'
      '${pad(d.inSeconds.remainder(60), 2)},'
      '${pad(d.inMilliseconds.remainder(1000), 3)}';
}
