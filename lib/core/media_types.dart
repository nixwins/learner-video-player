import 'package:file_selector/file_selector.dart';

/// Single source of truth for supported file types.
const videoExtensions = ['mp4', 'mkv', 'mov', 'avi'];
const subtitleExtensions = ['srt', 'vtt', 'ass'];

const videoTypeGroup = XTypeGroup(label: 'Video', extensions: videoExtensions);
const subtitleTypeGroup = XTypeGroup(
  label: 'Subtitles',
  extensions: subtitleExtensions,
);

enum MediaKind { video, subtitle, unsupported }

/// Classifies a file by its extension (case-insensitive).
MediaKind classifyMedia(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return MediaKind.unsupported;
  final extension = path.substring(dot + 1).toLowerCase();
  if (videoExtensions.contains(extension)) return MediaKind.video;
  if (subtitleExtensions.contains(extension)) return MediaKind.subtitle;
  return MediaKind.unsupported;
}

/// The file name of [path] without folders and extension: `/a/Friends S01.mp4`
/// becomes `Friends S01`. Works with both `/` and `\` separators.
String titleFromPath(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
