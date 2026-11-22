import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/youtube/domain/caption_cleaner.dart';

void main() {
  test('removes the lines that rolling auto captions repeat', () {
    const source = '''
1
00:00:00,160 --> 00:00:02,070
hello everyone welcome to

2
00:00:02,070 --> 00:00:02,080
hello everyone welcome to

3
00:00:02,080 --> 00:00:04,230
hello everyone welcome to
my channel today we

4
00:00:04,230 --> 00:00:04,240
my channel today we

5
00:00:04,240 --> 00:00:06,000
my channel today we
are going to learn
''';
    expect(cleanAutoCaptions(source), '''
1
00:00:00,160 --> 00:00:02,070
hello everyone welcome to

2
00:00:02,080 --> 00:00:04,230
my channel today we

3
00:00:04,240 --> 00:00:06,000
are going to learn

''');
  });

  test('reads WebVTT with tags, settings and short timestamps', () {
    const source = '''
WEBVTT
Kind: captions

00:01.000 --> 00:03.000 align:start position:0%
<c.colorE5E5E5>Hello</c><00:00:02.000><c> there</c>

00:03.000 --> 00:05.500
Fish &amp; chips
''';
    expect(cleanAutoCaptions(source), '''
1
00:00:01,000 --> 00:00:03,000
Hello there

2
00:00:03,000 --> 00:00:05,500
Fish & chips

''');
  });

  test('handles hours and Windows line endings', () {
    const source = '1\r\n01:02:03,004 --> 01:02:05,006\r\nHi\r\n\r\n';
    expect(
      cleanAutoCaptions(source),
      contains('01:02:03,004 --> 01:02:05,006'),
    );
  });

  test('keeps a line that comes back later in the video', () {
    const source = '''
1
00:00:01,000 --> 00:00:02,000
No.

2
00:00:02,000 --> 00:00:03,000
Really?

3
00:00:03,000 --> 00:00:04,000
No.
''';
    final cleaned = cleanAutoCaptions(source);
    expect('No.'.allMatches(cleaned).length, 2);
  });

  test('returns nothing for text without cues', () {
    expect(cleanAutoCaptions('not subtitles'), isEmpty);
  });
}
