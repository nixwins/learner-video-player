class _Cue {
  _Cue(this.start, this.end, this.lines);

  final Duration start;
  final Duration end;
  final List<String> lines;
}

final _timing = RegExp(
  r'(?:(\d+):)?(\d{1,2}):(\d{2})[.,](\d{3})\s*-->\s*'
  r'(?:(\d+):)?(\d{1,2}):(\d{2})[.,](\d{3})',
);
final _tags = RegExp(r'<[^>]*>');

/// Converts YouTube auto-generated captions (SRT or WebVTT) to a clean SRT.
///
/// Auto captions "roll": every cue repeats the previous line and adds a new
/// one, and tiny cues repeat everything. That would show every sentence twice
/// and break "play again", so each cue keeps only the lines it adds.
/// Use it for auto captions only: hand-written captions may repeat a line on
/// purpose.
String cleanAutoCaptions(String source) {
  final cues = _parse(source);
  final kept = <_Cue>[];
  var previous = <String>{};
  for (final cue in cues) {
    final fresh = cue.lines.where((line) => !previous.contains(line)).toList();
    previous = cue.lines.toSet();
    if (fresh.isNotEmpty) kept.add(_Cue(cue.start, cue.end, fresh));
  }
  return _write(kept);
}

List<_Cue> _parse(String source) {
  final cues = <_Cue>[];
  final blocks = source.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final lines = block.split('\n');
    final timingIndex = lines.indexWhere((line) => line.contains('-->'));
    if (timingIndex < 0) continue;
    final match = _timing.firstMatch(lines[timingIndex]);
    if (match == null) continue;
    final text = [
      for (final line in lines.skip(timingIndex + 1))
        _decode(line.replaceAll(_tags, '')).trim(),
    ].where((line) => line.isNotEmpty).toList();
    cues.add(_Cue(_time(match, 1), _time(match, 5), text));
  }
  return cues;
}

Duration _time(RegExpMatch m, int offset) => Duration(
  hours: int.parse(m.group(offset) ?? '0'),
  minutes: int.parse(m.group(offset + 1)!),
  seconds: int.parse(m.group(offset + 2)!),
  milliseconds: int.parse(m.group(offset + 3)!),
);

String _decode(String text) => text
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

String _write(List<_Cue> cues) {
  final out = StringBuffer();
  for (final (index, cue) in cues.indexed) {
    out
      ..writeln(index + 1)
      ..writeln('${_format(cue.start)} --> ${_format(cue.end)}')
      ..writeln(cue.lines.join('\n'))
      ..writeln();
  }
  return out.toString();
}

String _format(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)},$ms';
}
