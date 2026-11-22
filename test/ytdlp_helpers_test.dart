import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/youtube/data/executable_finder.dart';
import 'package:learner_video_player/features/youtube/data/ytdlp_video_resolver.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';

void main() {
  group('parseDownloadFraction', () {
    test('reads a progress line', () {
      expect(
        parseDownloadFraction('[download]  41.5% of  614.43KiB at 1MiB/s'),
        closeTo(0.415, 1e-9),
      );
    });

    test('reads 100%', () {
      expect(parseDownloadFraction('[download] 100% of 614.43KiB'), 1);
    });

    test('ignores other lines', () {
      expect(parseDownloadFraction('[youtube] Extracting URL'), isNull);
      expect(
        parseDownloadFraction('[download] Destination: video.mp4'),
        isNull,
      );
    });
  });

  group('pickEnglishCaptions', () {
    test('prefers hand-written captions', () {
      final choice = pickEnglishCaptions({
        'subtitles': {'de': [], 'en': []},
        'automatic_captions': {'en': []},
      });
      expect(choice?.language, 'en');
      expect(choice?.isAuto, isFalse);
    });

    test('accepts regional English', () {
      final choice = pickEnglishCaptions({
        'subtitles': {'en-GB': []},
      });
      expect(choice?.language, 'en-GB');
    });

    test('falls back to auto captions', () {
      final choice = pickEnglishCaptions({
        'subtitles': {'de': []},
        'automatic_captions': {'ru': [], 'en': []},
      });
      expect(choice?.language, 'en');
      expect(choice?.isAuto, isTrue);
    });

    test('uses the original-language auto track when there is no plain en', () {
      final choice = pickEnglishCaptions({
        'automatic_captions': {'en-orig': []},
      });
      expect(choice?.language, 'en-orig');
      expect(choice?.isAuto, isTrue);
    });

    test('does not mistake other languages for English', () {
      expect(
        pickEnglishCaptions({
          'subtitles': {'enm': [], 'es': []},
          'automatic_captions': {'es': []},
        }),
        isNull,
      );
    });

    test('handles videos with no captions at all', () {
      expect(pickEnglishCaptions({}), isNull);
    });
  });

  group('findExecutable', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('finder_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('finds a tool in the first folder that has it', () async {
      final a = Directory('${tmp.path}/a')..createSync();
      final b = Directory('${tmp.path}/b')..createSync();
      File('${b.path}/yt-dlp').createSync();
      expect(
        await findExecutable('yt-dlp', [a.path, b.path]),
        '${b.path}/yt-dlp',
      );
    });

    test('returns null when it is nowhere', () async {
      expect(
        await findExecutable('yt-dlp', [tmp.path, '/no/such/dir']),
        isNull,
      );
    });
  });

  group('defaultSearchDirs', () {
    test('includes PATH and the Homebrew folders on macOS', () {
      final dirs = defaultSearchDirs(
        environment: {'PATH': '/usr/bin:/bin', 'HOME': '/Users/me'},
        isWindows: false,
      );
      expect(dirs, containsAll(['/usr/bin', '/bin', '/opt/homebrew/bin']));
      expect(dirs, contains('/Users/me/.local/bin'));
    });

    test('splits PATH with semicolons on Windows', () {
      final dirs = defaultSearchDirs(
        environment: {
          'PATH': r'C:\a;C:\b',
          'LOCALAPPDATA': r'C:\Users\me\AppData\Local',
        },
        isWindows: true,
      );
      expect(dirs, containsAll([r'C:\a', r'C:\b']));
      expect(dirs.last, endsWith(r'WinGet\Links'));
    });
  });

  test('a missing yt-dlp gives a helpful install message', () async {
    final resolver = YtDlpVideoResolver(
      cacheRoot: Directory.systemTemp.createTempSync('resolver_test'),
      searchDirs: const ['/no/such/dir'],
    );
    await expectLater(
      resolver.resolve('https://youtu.be/jNQXAC9IVRw'),
      throwsA(
        isA<VideoResolveException>()
            .having((e) => e.error, 'error', VideoResolveError.toolMissing)
            .having(
              (e) => e.message,
              'message',
              contains('brew install yt-dlp'),
            ),
      ),
    );
  });

  test('a non-YouTube link is rejected before any tool is needed', () async {
    final resolver = YtDlpVideoResolver(searchDirs: const []);
    await expectLater(
      resolver.resolve('https://vimeo.com/1'),
      throwsA(
        isA<VideoResolveException>().having(
          (e) => e.error,
          'error',
          VideoResolveError.invalidUrl,
        ),
      ),
    );
  });
}
