import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/executable_finder.dart';
import 'package:learner_video_player/features/sentences/data/ffmpeg_clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';

String? _findSync(String name) {
  for (final dir in defaultSearchDirs()) {
    final file = File('$dir${Platform.pathSeparator}$name');
    if (file.existsSync()) return file.path;
  }
  return null;
}

void main() {
  group('buildClipArgs', () {
    final args = buildClipArgs(
      source: '/v/in.mp4',
      output: '/t/clip.mp4',
      from: const Duration(milliseconds: 9750),
      to: const Duration(milliseconds: 13300),
      audioStreamIndex: 1,
    );

    test('seeks before the input for a fast, accurate cut', () {
      expect(args.indexOf('-ss'), lessThan(args.indexOf('-i')));
      expect(args[args.indexOf('-ss') + 1], '9.750');
      expect(args[args.indexOf('-i') + 1], '/v/in.mp4');
    });

    test('limits the length to the fragment, not the end time', () {
      expect(args[args.indexOf('-t') + 1], '3.550');
    });

    test('picks the chosen audio track, optionally', () {
      expect(args, containsAllInOrder(['-map', '0:v:0', '-map', '0:a:1?']));
    });

    test('uses the first audio track when none is chosen', () {
      final defaults = buildClipArgs(
        source: 'a',
        output: 'b',
        from: Duration.zero,
        to: const Duration(seconds: 1),
      );
      expect(defaults, contains('0:a:0?'));
    });

    test('re-encodes to a web-friendly mp4 without subtitles', () {
      expect(args, containsAllInOrder(['-c:v', 'libx264']));
      expect(args, containsAllInOrder(['-c:a', 'aac']));
      expect(args, containsAllInOrder(['-movflags', '+faststart']));
      expect(args, contains('-sn'));
      expect(args.last, '/t/clip.mp4');
    });
  });

  test('a missing ffmpeg gives a helpful install message', () async {
    final cutter = FfmpegClipCutter(searchDirs: const ['/no/such/dir']);
    await expectLater(
      cutter.cut(
        sourcePath: '/x.mp4',
        from: Duration.zero,
        to: const Duration(seconds: 1),
      ),
      throwsA(
        isA<ClipException>().having(
          (e) => e.message,
          'message',
          contains('brew install ffmpeg'),
        ),
      ),
    );
  });

  final ffmpeg = _findSync('ffmpeg');
  final ffprobe = _findSync('ffprobe');
  final real = ffmpeg == null || ffprobe == null
      ? 'ffmpeg and ffprobe are not installed'
      : false;

  group('with real ffmpeg', () {
    late Directory tmp;
    late String source;
    late FfmpegClipCutter cutter;

    setUpAll(() async {
      tmp = Directory.systemTemp.createTempSync('cutter_test');
      source = '${tmp.path}/source.mp4';
      final made = await Process.run(ffmpeg!, [
        '-loglevel',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc=duration=6:size=320x240:rate=25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=6',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=880:duration=6',
        '-map',
        '0',
        '-map',
        '1',
        '-map',
        '2',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        source,
      ]);
      expect(made.exitCode, 0, reason: '${made.stderr}');
      cutter = FfmpegClipCutter(
        tempRoot: Directory('${tmp.path}/clips'),
        searchDirs: [File(ffmpeg).parent.path],
      );
    });

    tearDownAll(() => tmp.deleteSync(recursive: true));

    Future<Map<String, dynamic>> probe(String path) async {
      final result = await Process.run(ffprobe!, [
        '-v',
        'error',
        '-show_entries',
        'format=duration:stream=codec_type,codec_name',
        '-of',
        'json',
        path,
      ]);
      return jsonDecode(result.stdout as String) as Map<String, dynamic>;
    }

    test('cuts only the requested fragment into an mp4', () async {
      final clip = await cutter.cut(
        sourcePath: source,
        from: const Duration(seconds: 1),
        to: const Duration(milliseconds: 2500),
        audioStreamIndex: 1,
      );

      expect(clip.path, endsWith('.mp4'));
      expect(clip.bytes, greaterThan(0));

      final info = await probe(clip.path);
      final duration = double.parse(info['format']['duration'] as String);
      expect(duration, closeTo(1.5, 0.2));
      final streams = (info['streams'] as List).cast<Map<String, dynamic>>();
      expect(streams.where((s) => s['codec_type'] == 'video'), hasLength(1));
      expect(streams.where((s) => s['codec_type'] == 'audio'), hasLength(1));
      expect(
        streams.firstWhere((s) => s['codec_type'] == 'video')['codec_name'],
        'h264',
      );
      expect(
        streams.firstWhere((s) => s['codec_type'] == 'audio')['codec_name'],
        'aac',
      );
      await clip.discard();
    }, skip: real);

    test('discard removes the temporary files', () async {
      final clip = await cutter.cut(
        sourcePath: source,
        from: Duration.zero,
        to: const Duration(seconds: 1),
      );
      expect(File(clip.path).existsSync(), isTrue);

      await clip.discard();

      expect(File(clip.path).existsSync(), isFalse);
      expect(File(clip.path).parent.existsSync(), isFalse);
    }, skip: real);

    test('a missing audio track still produces a video', () async {
      final clip = await cutter.cut(
        sourcePath: source,
        from: Duration.zero,
        to: const Duration(seconds: 1),
        audioStreamIndex: 7,
      );
      expect(clip.bytes, greaterThan(0));
      await clip.discard();
    }, skip: real);

    test('a missing source file is reported', () async {
      await expectLater(
        cutter.cut(
          sourcePath: '${tmp.path}/nope.mp4',
          from: Duration.zero,
          to: const Duration(seconds: 1),
        ),
        throwsA(isA<ClipException>()),
      );
    }, skip: real);

    test('a file ffmpeg cannot read is reported and leaves no files', () async {
      final broken = File('${tmp.path}/broken.mp4')..writeAsStringSync('nope');
      await expectLater(
        cutter.cut(
          sourcePath: broken.path,
          from: Duration.zero,
          to: const Duration(seconds: 1),
        ),
        throwsA(isA<ClipException>()),
      );
      final clips = Directory('${tmp.path}/clips');
      expect(clips.listSync().whereType<Directory>(), isEmpty);
    }, skip: real);
  });
}
