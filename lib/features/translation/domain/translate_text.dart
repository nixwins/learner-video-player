import 'package:learner_video_player/features/translation/domain/translate_url_builder.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

/// Use case: translate a word or a whole sentence from English into the
/// user's native language.
class TranslateText {
  const TranslateText(this._launcher);

  static const sourceLanguageCode = 'en';

  final TranslationLauncher _launcher;

  Future<void> call(String text, {required String targetLanguageCode}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    return _launcher.open(
      buildTranslateUri(
        text: trimmed,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
      ),
    );
  }
}
