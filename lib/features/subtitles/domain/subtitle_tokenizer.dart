/// A piece of a subtitle line: either a clickable word or a separator
/// (spaces, punctuation).
class SubtitleToken {
  const SubtitleToken(this.text, {required this.isWord});

  final String text;
  final bool isWord;

  @override
  bool operator ==(Object other) =>
      other is SubtitleToken && other.text == text && other.isWord == isWord;

  @override
  int get hashCode => Object.hash(text, isWord);

  @override
  String toString() => 'SubtitleToken($text, isWord: $isWord)';
}

// Markup that may remain in subtitle text: <i>..</i> and ASS {\an8}.
final _markup = RegExp(r'<[^>]+>|\{[^}]*\}');

// A word is letters (any script) with optional apostrophe parts: it's, don't.
final _word = RegExp(r"[\p{L}\p{M}]+(?:['’][\p{L}\p{M}]+)*", unicode: true);

/// Splits one subtitle [line] into words and separators, preserving order.
List<SubtitleToken> tokenizeSubtitle(String line) {
  final clean = line.replaceAll(_markup, '');
  final tokens = <SubtitleToken>[];
  var cursor = 0;
  for (final match in _word.allMatches(clean)) {
    if (match.start > cursor) {
      tokens.add(
        SubtitleToken(clean.substring(cursor, match.start), isWord: false),
      );
    }
    tokens.add(SubtitleToken(match.group(0)!, isWord: true));
    cursor = match.end;
  }
  if (cursor < clean.length) {
    tokens.add(SubtitleToken(clean.substring(cursor), isWord: false));
  }
  return tokens;
}
