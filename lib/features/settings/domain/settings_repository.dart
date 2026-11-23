abstract interface class SettingsRepository {
  /// The saved native language code, or null if the user never chose one.
  String? get nativeLanguageCode;

  Future<void> saveNativeLanguageCode(String code);

  /// The saved translation panel width, or null if the user never resized it.
  double? get translationPanelWidth;

  Future<void> saveTranslationPanelWidth(double width);

  /// The FreqApp server address, or null if it was never set.
  String? get freqAppServer;

  Future<void> saveFreqAppServer(String server);

  /// The FreqApp API key, or null if it was never set. It is a secret: never
  /// log it.
  String? get freqAppApiKey;

  Future<void> saveFreqAppApiKey(String apiKey);
}
