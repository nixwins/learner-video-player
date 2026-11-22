/// Builds the Google Translate web URL for [text].
///
/// This is the only place that knows the URL format.
Uri buildTranslateUri({
  required String text,
  required String sourceLanguageCode,
  required String targetLanguageCode,
}) {
  return Uri.https('translate.google.com', '/', {
    'sl': sourceLanguageCode,
    'tl': targetLanguageCode,
    'text': text,
    'op': 'translate',
  });
}
