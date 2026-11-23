import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

void main() {
  test('fromRaw joins lines and strips markup', () {
    final cue = SubtitleCue.fromRaw('<i>I know</i> that\n{\\an8}you are  here');
    expect(cue.text, 'I know that you are  here');
  });

  test('fromRaw skips blank lines', () {
    expect(SubtitleCue.fromRaw('Hello\n\n  \nworld').text, 'Hello world');
  });

  test('can replay only with a valid start and end', () {
    expect(const SubtitleCue(text: 'a').canReplay, isFalse);
    expect(
      const SubtitleCue(text: 'a', start: Duration(seconds: 1)).canReplay,
      isFalse,
    );
    expect(
      const SubtitleCue(
        text: 'a',
        start: Duration(seconds: 3),
        end: Duration(seconds: 3),
      ).canReplay,
      isFalse,
    );
    expect(
      const SubtitleCue(
        text: 'a',
        start: Duration(seconds: 3),
        end: Duration(seconds: 5),
      ).canReplay,
      isTrue,
    );
  });

  test('replay starts a little before the cue', () {
    const cue = SubtitleCue(
      text: 'a',
      start: Duration(seconds: 10),
      end: Duration(seconds: 12),
    );
    expect(cue.replayFrom, const Duration(milliseconds: 9750));
  });

  test('replay never starts before the beginning of the video', () {
    const cue = SubtitleCue(
      text: 'a',
      start: Duration(milliseconds: 100),
      end: Duration(seconds: 2),
    );
    expect(cue.replayFrom, Duration.zero);
  });

  test(
    'a saved clip starts like play again and ends a little after the cue',
    () {
      const cue = SubtitleCue(
        text: 'a',
        start: Duration(seconds: 10),
        end: Duration(seconds: 13),
      );
      expect(cue.clipFrom, const Duration(milliseconds: 9750));
      expect(cue.clipTo, const Duration(milliseconds: 13300));
    },
  );
}
