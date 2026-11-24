import 'dart:io';

import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_library.dart';
import 'package:learner_video_player/features/subtitles/domain/single_cue_srt.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Keeps the list in a SQLite database and each video fragment as a file next
/// to it. Only file names are stored, so the whole folder can be moved.
class SqliteSentenceLibrary implements SentenceLibrary {
  SqliteSentenceLibrary._(this._db, this._dir);

  static const _table = 'sentences';

  final Database _db;
  final Directory _dir;

  /// Opens (and creates, if needed) the database inside [directory].
  static Future<SqliteSentenceLibrary> open(
    Directory directory,
    DatabaseFactory factory,
  ) async {
    await directory.create(recursive: true);
    final db = await factory.openDatabase(
      '${directory.path}${Platform.pathSeparator}sentences.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            show_name TEXT,
            saved_at INTEGER NOT NULL,
            clip_file TEXT,
            subtitle_file TEXT
          )
        '''),
      ),
    );
    return SqliteSentenceLibrary._(db, directory);
  }

  @override
  String get folder => _dir.path;

  Future<void> close() => _db.close();

  String _path(String file) => '${_dir.path}${Platform.pathSeparator}$file';

  @override
  Future<LocalSentence> add({
    required String text,
    String? showName,
    Clip? clip,
    Duration? clipDuration,
  }) async {
    final savedAt = DateTime.now();
    final id = await _db.insert(_table, {
      'text': text,
      'show_name': showName,
      'saved_at': savedAt.millisecondsSinceEpoch,
    });
    String? clipFile;
    String? subtitleFile;
    try {
      if (clip != null) {
        clipFile = 'sentence-$id.mp4';
        await File(clip.path).copy(_path(clipFile));
        if (clipDuration != null) {
          subtitleFile = 'sentence-$id.srt';
          await File(
            _path(subtitleFile),
          ).writeAsString(singleCueSrt(text, clipDuration));
        }
        await _db.update(
          _table,
          {'clip_file': clipFile, 'subtitle_file': subtitleFile},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      await _deleteFiles(clipFile, subtitleFile);
      await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
      rethrow;
    }
    return LocalSentence(
      id: id,
      text: text,
      showName: showName,
      savedAt: savedAt,
      videoPath: clipFile == null ? null : _path(clipFile),
      subtitlePath: subtitleFile == null ? null : _path(subtitleFile),
    );
  }

  @override
  Future<List<LocalSentence>> all() async {
    final rows = await _db.query(_table, orderBy: 'id DESC');
    return [
      for (final row in rows)
        LocalSentence(
          id: row['id'] as int,
          text: row['text'] as String,
          showName: row['show_name'] as String?,
          savedAt: DateTime.fromMillisecondsSinceEpoch(row['saved_at'] as int),
          videoPath: _existing(row['clip_file'] as String?),
          subtitlePath: _existing(row['subtitle_file'] as String?),
        ),
    ];
  }

  /// A file that was deleted by hand counts as missing, not as a broken row.
  String? _existing(String? file) {
    if (file == null) return null;
    final path = _path(file);
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<void> remove(int id) async {
    final rows = await _db.query(
      _table,
      columns: ['clip_file', 'subtitle_file'],
      where: 'id = ?',
      whereArgs: [id],
    );
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      await _deleteFiles(
        rows.first['clip_file'] as String?,
        rows.first['subtitle_file'] as String?,
      );
    }
  }

  Future<void> _deleteFiles(String? clipFile, String? subtitleFile) async {
    for (final file in [clipFile, subtitleFile].whereType<String>()) {
      try {
        await File(_path(file)).delete();
      } on FileSystemException {
        continue;
      }
    }
  }
}
