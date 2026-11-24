import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/subtitles/domain/single_cue_srt.dart';

void main() {
  test('shows the sentence from the start to the end of the clip', () {
    expect(
      singleCueSrt('Hello there', const Duration(seconds: 3)),
      '1\n00:00:00,000 --> 00:00:03,000\nHello there\n',
    );
  });

  test('formats minutes, hours and milliseconds', () {
    expect(
      singleCueSrt(
        '  Hi  ',
        const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 45),
      ),
      '1\n00:00:00,000 --> 01:02:03,045\nHi\n',
    );
  });
}
