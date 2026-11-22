import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/duration_format.dart';
import 'package:learner_video_player/core/media_types.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 5)), '00:05');
    expect(formatDuration(const Duration(minutes: 12, seconds: 3)), '12:03');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('classifyMedia', () {
    expect(classifyMedia('/a/b/movie.MP4'), MediaKind.video);
    expect(classifyMedia('movie.avi'), MediaKind.video);
    expect(classifyMedia('movie.mov'), MediaKind.video);
    expect(classifyMedia('movie.en.srt'), MediaKind.subtitle);
    expect(classifyMedia('notes.txt'), MediaKind.unsupported);
    expect(classifyMedia('noextension'), MediaKind.unsupported);
  });
}
