import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_tokenizer.dart';

void main() {
  SubtitleToken word(String text) => SubtitleToken(text, isWord: true);
  SubtitleToken sep(String text) => SubtitleToken(text, isWord: false);

  test('splits words and separators in order', () {
    expect(tokenizeSubtitle("Hello, it's fine."), [
      word('Hello'),
      sep(', '),
      word("it's"),
      sep(' '),
      word('fine'),
      sep('.'),
    ]);
  });

  test('strips HTML and ASS markup', () {
    expect(tokenizeSubtitle(r'{\an8}<i>Run</i> away'), [
      word('Run'),
      sep(' '),
      word('away'),
    ]);
  });

  test('keeps non-latin letters as words', () {
    expect(tokenizeSubtitle('Привет мир'), [
      word('Привет'),
      sep(' '),
      word('мир'),
    ]);
  });

  test('numbers and punctuation are not words', () {
    expect(tokenizeSubtitle('... 42 ?!'), [sep('... 42 ?!')]);
  });

  test('empty line gives no tokens', () {
    expect(tokenizeSubtitle(''), isEmpty);
  });
}
