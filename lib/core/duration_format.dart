/// Formats a duration as `mm:ss`, or `h:mm:ss` when it is an hour or longer.
String formatDuration(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = two(duration.inMinutes.remainder(60));
  final seconds = two(duration.inSeconds.remainder(60));
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
