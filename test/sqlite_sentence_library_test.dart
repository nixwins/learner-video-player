import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/sentences/data/sqlite_sentence_library.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late Directory scratch;
  late SqliteSentenceLibrary library;

  Clip clip(String content) {
    final file = File('${scratch.path}/clip.mp4')..writeAsStringSync(content);
    return Clip(path: file.path, bytes: content.length, discard: () async {});
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('library_test');
    scratch = Directory.systemTemp.createTempSync('library_scratch');
    library = await SqliteSentenceLibrary.open(dir, databaseFactoryFfi);
  });

  tearDown(() async {
    await library.close();
    dir.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  });

  test('is empty at first', () async {
    expect(await library.all(), isEmpty);
  });

  test('stores the sentence and copies its clip into the folder', () async {
    final saved = await library.add(
      text: 'I know the government',
      showName: 'Friends',
      clip: clip('video-bytes'),
      clipDuration: const Duration(seconds: 3, milliseconds: 550),
    );

    expect(saved.videoPath, startsWith(dir.path));
    expect(File(saved.videoPath!).readAsStringSync(), 'video-bytes');
    expect(
      File(saved.subtitlePath!).readAsStringSync(),
      '1\n00:00:00,000 --> 00:00:03,550\nI know the government\n',
    );

    final listed = (await library.all()).single;
    expect(listed.text, 'I know the government');
    expect(listed.showName, 'Friends');
    expect(listed.videoPath, saved.videoPath);
    expect(listed.subtitlePath, saved.subtitlePath);
    expect(listed.hasVideo, isTrue);
  });

  test('a sentence without a clip has no files', () async {
    final saved = await library.add(text: 'Hello');

    expect(saved.hasVideo, isFalse);
    expect(saved.subtitlePath, isNull);
    expect(dir.listSync().whereType<File>().map((f) => f.path), [
      contains('sentences.db'),
    ]);
  });

  test('lists the newest sentence first', () async {
    await library.add(text: 'first');
    await library.add(text: 'second');

    expect((await library.all()).map((s) => s.text), ['second', 'first']);
  });

  test('keeps the list after the database is reopened', () async {
    await library.add(text: 'remember me', clip: clip('x'));
    await library.close();

    library = await SqliteSentenceLibrary.open(dir, databaseFactoryFfi);

    final listed = (await library.all()).single;
    expect(listed.text, 'remember me');
    expect(File(listed.videoPath!).existsSync(), isTrue);
  });

  test('removing deletes the row and its files', () async {
    final saved = await library.add(
      text: 'gone',
      clip: clip('x'),
      clipDuration: const Duration(seconds: 2),
    );
    await library.add(text: 'stays');

    await library.remove(saved.id);

    expect((await library.all()).map((s) => s.text), ['stays']);
    expect(File(saved.videoPath!).existsSync(), isFalse);
    expect(File(saved.subtitlePath!).existsSync(), isFalse);
  });

  test('a clip deleted by hand just loses its video', () async {
    final saved = await library.add(text: 'half', clip: clip('x'));
    File(saved.videoPath!).deleteSync();

    final listed = (await library.all()).single;
    expect(listed.text, 'half');
    expect(listed.hasVideo, isFalse);
  });

  test('a failed copy leaves no row behind', () async {
    final missing = Clip(
      path: '${scratch.path}/no-such-file.mp4',
      bytes: 1,
      discard: () async {},
    );

    await expectLater(
      library.add(text: 'broken', clip: missing),
      throwsA(isA<FileSystemException>()),
    );
    expect(await library.all(), isEmpty);
  });

  test('the folder is created when missing', () async {
    final nested = Directory('${dir.path}/a/b');
    final other = await SqliteSentenceLibrary.open(nested, databaseFactoryFfi);
    expect(nested.existsSync(), isTrue);
    expect(other.folder, nested.path);
    await other.close();
  });
}
