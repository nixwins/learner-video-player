import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/translation/domain/translate_url_builder.dart';
import 'package:learner_video_player/features/translation/domain/translate_text.dart';
import 'support/fakes.dart';

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

  test('TranslateText opens en -> target and trims the text', () async {
    final launcher = FakeTranslationLauncher();
    await TranslateText(launcher)(' actually ', targetLanguageCode: 'kk');
    expect(launcher.opened.single.queryParameters['sl'], 'en');
    expect(launcher.opened.single.queryParameters['tl'], 'kk');
    expect(launcher.opened.single.queryParameters['text'], 'actually');
  });

  test('TranslateText translates a whole sentence in one request', () async {
    final launcher = FakeTranslationLauncher();
    await TranslateText(launcher)(
      'I know the government.',
      targetLanguageCode: 'ru',
    );
    expect(
      launcher.opened.single.queryParameters['text'],
      'I know the government.',
    );
  });

  test('TranslateText ignores blank input', () async {
    final launcher = FakeTranslationLauncher();
    await TranslateText(launcher)('  ', targetLanguageCode: 'kk');
    expect(launcher.opened, isEmpty);
  });
}
