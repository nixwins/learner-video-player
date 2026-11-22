import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/youtube/domain/youtube_url.dart';

void main() {
  const id = 'jNQXAC9IVRw';

  group('youtubeVideoId accepts', () {
    for (final (name, url) in [
      ('watch link', 'https://www.youtube.com/watch?v=$id'),
      (
        'watch link with extra params',
        'https://www.youtube.com/watch?v=$id&t=42s&list=PL1',
      ),
      ('link without www', 'https://youtube.com/watch?v=$id'),
      ('mobile link', 'https://m.youtube.com/watch?v=$id'),
      ('music link', 'https://music.youtube.com/watch?v=$id'),
      ('short link', 'https://youtu.be/$id'),
      ('short link with time', 'https://youtu.be/$id?t=10'),
      ('shorts', 'https://www.youtube.com/shorts/$id'),
      ('embed', 'https://www.youtube.com/embed/$id'),
      ('live', 'https://www.youtube.com/live/$id'),
      ('link without scheme', 'www.youtube.com/watch?v=$id'),
      ('link with spaces around', '  https://youtu.be/$id  '),
      ('http link', 'http://youtu.be/$id'),
    ]) {
      test(name, () => expect(youtubeVideoId(url), id));
    }
  });

  group('youtubeVideoId rejects', () {
    for (final (name, url) in [
      ('empty text', ''),
      ('plain words', 'hello world'),
      ('another site', 'https://vimeo.com/watch?v=$id'),
      ('look-alike host', 'https://notyoutube.com/watch?v=$id'),
      ('host in the path', 'https://example.com/youtube.com/watch?v=$id'),
      ('channel page', 'https://www.youtube.com/@somebody'),
      ('playlist page', 'https://www.youtube.com/playlist?list=PL123'),
      ('watch without id', 'https://www.youtube.com/watch'),
      ('too short id', 'https://youtu.be/abc'),
      ('other scheme', 'ftp://youtu.be/$id'),
      ('text with a link inside', 'watch this https://youtu.be/$id'),
    ]) {
      test(name, () => expect(youtubeVideoId(url), isNull));
    }
  });
}
