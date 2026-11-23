import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:learner_video_player/core/executable_finder.dart';
import 'package:learner_video_player/features/youtube/domain/caption_cleaner.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';
import 'package:learner_video_player/features/youtube/domain/youtube_url.dart';

final _percent = RegExp(r'\[download\]\s+(\d+(?:\.\d+)?)%');

/// Parses a yt-dlp progress line such as `[download]  41.5% of 3MiB` into
/// 0..1, or null for any other line.
double? parseDownloadFraction(String line) {
  final match = _percent.firstMatch(line);
  if (match == null) return null;
  return (double.parse(match.group(1)!) / 100).clamp(0.0, 1.0);
}

/// Which English captions a video offers.
class CaptionChoice {
  const CaptionChoice(this.language, {required this.isAuto});

  final String language;
  final bool isAuto;
}

/// Prefers hand-written English captions over auto-generated ones.
CaptionChoice? pickEnglishCaptions(Map<String, dynamic> info) {
  final manual = (info['subtitles'] as Map?)?.keys.cast<String>() ?? const [];
  final auto =
      (info['automatic_captions'] as Map?)?.keys.cast<String>() ?? const [];
  bool isEnglish(String key) => key == 'en' || key.startsWith('en-');

  for (final key in manual) {
    if (isEnglish(key)) return CaptionChoice(key, isAuto: false);
  }
  for (final key in const ['en', 'en-orig']) {
    if (auto.contains(key)) return CaptionChoice(key, isAuto: true);
  }
  return null;
}

/// The only place that knows about yt-dlp. Downloads a video (up to 720p) and
/// its English captions into a cache folder, then hands back plain files.
class YtDlpVideoResolver implements VideoResolver {
  YtDlpVideoResolver({Directory? cacheRoot, List<String>? searchDirs})
    : _cacheRoot =
          cacheRoot ??
          Directory(
            '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'learner_video_player${Platform.pathSeparator}youtube',
          ),
      _searchDirs = searchDirs ?? defaultSearchDirs();

  static const _videoExtensions = {'mp4', 'mkv', 'webm', 'mov', 'm4v', 'avi'};
  static const _marker = 'done.json';

  final Directory _cacheRoot;
  final List<String> _searchDirs;

  @override
  Future<ResolvedVideo> resolve(
    String url, {
    void Function(ResolveProgress progress)? onProgress,
    Cancellation? cancellation,
  }) async {
    final id = youtubeVideoId(url);
    if (id == null) {
      throw const VideoResolveException(
        VideoResolveError.invalidUrl,
        'This does not look like a link to a YouTube video.',
      );
    }

    final dir = Directory('${_cacheRoot.path}${Platform.pathSeparator}$id');
    final cached = await _readCache(dir);
    if (cached != null) return cached;

    final ytDlp = await findExecutable(
      Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp',
      _searchDirs,
    );
    if (ytDlp == null) {
      throw const VideoResolveException(
        VideoResolveError.toolMissing,
        'yt-dlp is not installed. Install it with "brew install yt-dlp" '
        '(macOS) or "winget install yt-dlp" (Windows) and try again.',
      );
    }
    final ffmpeg = await findExecutable(
      Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg',
      _searchDirs,
    );

    onProgress?.call(const ResolveProgress(ResolveStage.preparing));
    final info = await _fetchInfo(ytDlp, url, cancellation);
    final title = (info['title'] as String?) ?? 'YouTube video';
    final captions = pickEnglishCaptions(info);

    await dir.create(recursive: true);
    final args = [
      '--no-playlist',
      '--no-warnings',
      '--newline',
      '--no-colors',
      '-f',
      ffmpeg != null
          ? 'bv*[height<=720]+ba/b[height<=720]/b'
          : 'b[height<=720]/b',
      if (ffmpeg != null) ...['--ffmpeg-location', ffmpeg],
      '--merge-output-format',
      'mp4',
      '-o',
      '${dir.path}${Platform.pathSeparator}video.%(ext)s',
      if (captions != null) ...[
        captions.isAuto ? '--write-auto-subs' : '--write-subs',
        '--sub-langs',
        captions.language,
        '--sub-format',
        'srt/vtt/best',
      ],
      url,
    ];
    final result = await _run(
      ytDlp,
      args,
      cancellation,
      onLine: (line) {
        final fraction = parseDownloadFraction(line);
        if (fraction != null) {
          onProgress?.call(
            ResolveProgress(
              ResolveStage.downloading,
              fraction: fraction,
              title: title,
            ),
          );
        }
      },
    );
    if (result.exitCode != 0) throw _failure(result.stderr);

    final video = await _findVideo(dir);
    if (video == null) {
      throw const VideoResolveException(
        VideoResolveError.failed,
        'The download finished but no video file was found.',
      );
    }
    final subtitle = captions == null
        ? null
        : await _prepareSubtitle(dir, captions);

    final resolved = ResolvedVideo(
      title: title,
      videoPath: video.path,
      subtitlePath: subtitle?.path,
    );
    await _writeCache(dir, resolved);
    return resolved;
  }

  Future<Map<String, dynamic>> _fetchInfo(
    String ytDlp,
    String url,
    Cancellation? cancellation,
  ) async {
    final result = await _run(ytDlp, [
      '-J',
      '--no-playlist',
      '--no-warnings',
      url,
    ], cancellation);
    if (result.exitCode != 0) throw _failure(result.stderr);
    return jsonDecode(result.stdout) as Map<String, dynamic>;
  }

  Future<File?> _findVideo(Directory dir) async {
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final extension = name.split('.').last.toLowerCase();
      if (name.startsWith('video.') && _videoExtensions.contains(extension)) {
        return entity;
      }
    }
    return null;
  }

  /// Returns the English subtitles as a clean .srt, or null if yt-dlp did not
  /// produce any.
  Future<File?> _prepareSubtitle(Directory dir, CaptionChoice captions) async {
    final base =
        '${dir.path}${Platform.pathSeparator}video.${captions.language}';
    for (final extension in const ['srt', 'vtt']) {
      final file = File('$base.$extension');
      if (!await file.exists()) continue;
      if (!captions.isAuto && extension == 'srt') return file;
      final clean = File('${dir.path}${Platform.pathSeparator}video.clean.srt');
      final text = await file.readAsString();
      await clean.writeAsString(
        captions.isAuto ? cleanAutoCaptions(text) : text,
      );
      return clean;
    }
    return null;
  }

  Future<ResolvedVideo?> _readCache(Directory dir) async {
    final marker = File('${dir.path}${Platform.pathSeparator}$_marker');
    if (!await marker.exists()) return null;
    try {
      final data = jsonDecode(await marker.readAsString()) as Map;
      final video = data['video'] as String;
      final subtitle = data['subtitle'] as String?;
      if (!await File(video).exists()) return null;
      if (subtitle != null && !await File(subtitle).exists()) return null;
      return ResolvedVideo(
        title: data['title'] as String,
        videoPath: video,
        subtitlePath: subtitle,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(Directory dir, ResolvedVideo video) =>
      File('${dir.path}${Platform.pathSeparator}$_marker').writeAsString(
        jsonEncode({
          'title': video.title,
          'video': video.videoPath,
          'subtitle': video.subtitlePath,
        }),
      );

  Future<_RunResult> _run(
    String executable,
    List<String> args,
    Cancellation? cancellation, {
    void Function(String line)? onLine,
  }) async {
    final separator = Platform.isWindows ? ';' : ':';
    final process = await Process.start(
      executable,
      args,
      environment: {'PATH': _searchDirs.join(separator)},
    );
    unawaited(cancellation?.whenCancelled.then((_) => process.kill()));

    final stdout = StringBuffer();
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          if (onLine == null) stdout.writeln(line);
          onLine?.call(line);
        });
    final stderrText = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    await stdoutDone;
    final stderr = await stderrText;

    if (cancellation?.isCancelled ?? false) {
      throw const VideoResolveException(
        VideoResolveError.cancelled,
        'Cancelled.',
      );
    }
    return _RunResult(exitCode, stdout.toString(), stderr);
  }

  VideoResolveException _failure(String stderr) {
    final lines = stderr
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('ERROR'))
        .toList();
    final detail = lines.isEmpty ? stderr.trim() : lines.last;

    if (detail.contains('403')) {
      return const VideoResolveException(
        VideoResolveError.failed,
        'YouTube refused the download (HTTP 403). Your yt-dlp is probably out '
        'of date. Update it ("brew upgrade yt-dlp" or "pip install -U '
        'yt-dlp") and try again.',
      );
    }
    if (detail.contains('unavailable') ||
        detail.contains('Private video') ||
        detail.contains('removed')) {
      return VideoResolveException(
        VideoResolveError.unavailable,
        'This video is not available. $detail',
      );
    }
    if (detail.contains('Sign in')) {
      return VideoResolveException(
        VideoResolveError.failed,
        'YouTube wants you to sign in to watch this video. $detail',
      );
    }
    return VideoResolveException(
      VideoResolveError.failed,
      detail.isEmpty ? 'yt-dlp failed.' : detail,
    );
  }
}

class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}
