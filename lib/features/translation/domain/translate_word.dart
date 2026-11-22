import 'package:learner_video_player/features/translation/domain/translate_url_builder.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

/// Use case: translate [word] from English into the user's native language.
class TranslateWord {
  const TranslateWord(this._launcher);

  static const sourceLanguageCode = 'en';

  final TranslationLauncher _launcher;

  Future<void> call(String word, {required String targetLanguageCode}) {
    final text = word.trim();
    if (text.isEmpty) return Future.value();
    return _launcher.open(
      buildTranslateUri(
        text: text,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
      ),
    );
  }
}
