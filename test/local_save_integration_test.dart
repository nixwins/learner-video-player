import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/executable_finder.dart';
import 'package:learner_video_player/features/player/domain/video_source.dart';
import 'package:learner_video_player/features/sentences/data/ffmpeg_clip_cutter.dart';
import 'package:learner_video_player/features/sentences/data/sqlite_sentence_library.dart';
import 'package:learner_video_player/features/sentences/domain/save_sentence.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fakes.dart';

String? _find(String name) {
  for (final dir in defaultSearchDirs()) {
    final file = File('$dir${Platform.pathSeparator}$name');
    if (file.existsSync()) return file.path;
  }
  return null;
}

void main() {
  sqfliteFfiInit();
  final ffmpeg = _find('ffmpeg');
  final ffprobe = _find('ffprobe');

  test(
    'a sentence is cut, copied into the folder and listed',
    () async {
      final tmp = Directory.systemTemp.createTempSync('local_save');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final source = '${tmp.path}/source.mp4';
      final made = await Process.run(ffmpeg!, [
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'testsrc=duration=8:size=320x240:rate=25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=8',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-c:a',
        'aac',
        source,
      ]);
      expect(made.exitCode, 0, reason: '${made.stderr}');

      final library = await SqliteSentenceLibrary.open(
        Directory('${tmp.path}/library'),
        databaseFactoryFfi,
      );
      addTearDown(library.close);
      final clips = Directory('${tmp.path}/clips');
      final save = SaveSentence(
        repository: FakeSentenceRepository(),
        cutter: FfmpegClipCutter(
          tempRoot: clips,
          searchDirs: [File(ffmpeg).parent.path],
        ),
        library: library,
      );

      await save.saveLocally(
        cue: const SubtitleCue(
          text: 'This is the sentence',
          start: Duration(seconds: 2),
          end: Duration(seconds: 4),
        ),
        source: VideoSource(path: source, title: 'My Show'),
      );

      final listed = (await library.all()).single;
      expect(listed.text, 'This is the sentence');
      expect(listed.showName, 'My Show');
      final probe = await Process.run(ffprobe!, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'csv=p=0',
        listed.videoPath!,
      ]);
      final seconds = double.parse((probe.stdout as String).trim());
      expect(seconds, closeTo(2.55, 0.3));
      expect(
        File(listed.subtitlePath!).readAsStringSync(),
        contains('This is the sentence'),
      );
      expect(
        clips.existsSync() ? clips.listSync() : <FileSystemEntity>[],
        isEmpty,
        reason: 'the temporary clip is removed',
      );
    },
    skip: ffmpeg == null || ffprobe == null
        ? 'ffmpeg and ffprobe are not installed'
        : false,
  );
}
