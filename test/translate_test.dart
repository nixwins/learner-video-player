import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/translation/domain/translate_url_builder.dart';
import 'package:learner_video_player/features/translation/domain/translate_word.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

class _FakeLauncher implements TranslationLauncher {
  final opened = <Uri>[];

  @override
  Future<void> open(Uri uri) async => opened.add(uri);
}

void main() {
  test('builds the Google Translate URL', () {
    final uri = buildTranslateUri(
      text: 'actually',
      sourceLanguageCode: 'en',
      targetLanguageCode: 'kk',
    );
    expect(uri.host, 'translate.google.com');
    expect(uri.queryParameters, {
      'sl': 'en',
      'tl': 'kk',
      'text': 'actually',
      'op': 'translate',
    });
  });

  test('encodes text safely', () {
    final uri = buildTranslateUri(
      text: 'a&b c',
      sourceLanguageCode: 'en',
      targetLanguageCode: 'ru',
    );
    expect(uri.queryParameters['text'], 'a&b c');
  });

  test('TranslateWord opens en -> target and trims the word', () async {
    final launcher = _FakeLauncher();
    await TranslateWord(launcher)(' actually ', targetLanguageCode: 'kk');
    expect(launcher.opened.single.queryParameters['sl'], 'en');
    expect(launcher.opened.single.queryParameters['tl'], 'kk');
    expect(launcher.opened.single.queryParameters['text'], 'actually');
  });

  test('TranslateWord ignores blank input', () async {
    final launcher = _FakeLauncher();
    await TranslateWord(launcher)('  ', targetLanguageCode: 'kk');
    expect(launcher.opened, isEmpty);
  });
}
