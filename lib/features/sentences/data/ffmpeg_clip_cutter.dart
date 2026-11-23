import 'dart:io';

import 'package:learner_video_player/core/executable_finder.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';

String _seconds(Duration duration) =>
    (duration.inMilliseconds / 1000).toStringAsFixed(3);

/// The ffmpeg arguments that cut [from]..[to] out of [source] into an .mp4.
///
/// The fragment is re-encoded (H.264 + AAC) because copying streams can only
/// cut on keyframes, which would start the clip at the wrong word. Seeking
/// before the input keeps this fast and still frame-accurate when re-encoding.
List<String> buildClipArgs({
  required String source,
  required String output,
  required Duration from,
  required Duration to,
  int? audioStreamIndex,
}) {
  return [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-ss',
    _seconds(from),
    '-i',
    source,
    '-t',
    _seconds(to - from),
    '-map',
    '0:v:0',
    '-map',
    '0:a:${audioStreamIndex ?? 0}?',
    '-sn',
    '-dn',
    '-c:v',
    'libx264',
    '-preset',
    'veryfast',
    '-crf',
    '23',
    '-pix_fmt',
    'yuv420p',
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    '-ac',
    '2',
    '-movflags',
    '+faststart',
    output,
  ];
}

/// The only place that runs ffmpeg for clips.
class FfmpegClipCutter implements ClipCutter {
  FfmpegClipCutter({Directory? tempRoot, List<String>? searchDirs})
    : _tempRoot =
          tempRoot ??
          Directory(
            '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'learner_video_player${Platform.pathSeparator}clips',
          ),
      _searchDirs = searchDirs ?? defaultSearchDirs();

  final Directory _tempRoot;
  final List<String> _searchDirs;

  @override
  Future<Clip> cut({
    required String sourcePath,
    required Duration from,
    required Duration to,
    int? audioStreamIndex,
  }) async {
    final ffmpeg = await findExecutable(
      Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg',
      _searchDirs,
    );
    if (ffmpeg == null) {
      throw const ClipException(
        'ffmpeg is not installed. Install it with "brew install ffmpeg" '
        '(macOS) or "winget install ffmpeg" (Windows) and try again.',
      );
    }
    if (!await File(sourcePath).exists()) {
      throw ClipException('The video file was not found: $sourcePath');
    }

    await _tempRoot.create(recursive: true);
    final dir = await _tempRoot.createTemp('clip');
    final output = '${dir.path}${Platform.pathSeparator}clip.mp4';

    Future<void> discard() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    }

    final result = await Process.run(
      ffmpeg,
      buildClipArgs(
        source: sourcePath,
        output: output,
        from: from,
        to: to,
        audioStreamIndex: audioStreamIndex,
      ),
    );
    final file = File(output);
    if (result.exitCode != 0 || !await file.exists()) {
      await discard();
      throw ClipException(
        'ffmpeg could not cut the video fragment. ${_lastLine(result.stderr)}',
      );
    }
    return Clip(path: output, bytes: await file.length(), discard: discard);
  }

  String _lastLine(Object? stderr) {
    final lines = '$stderr'
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return lines.isEmpty ? '' : lines.last;
  }
}
