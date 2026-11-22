abstract interface class SettingsRepository {
  /// The saved native language code, or null if the user never chose one.
  String? get nativeLanguageCode;

  Future<void> saveNativeLanguageCode(String code);

  /// The saved translation panel width, or null if the user never resized it.
  double? get translationPanelWidth;

  Future<void> saveTranslationPanelWidth(double width);
}
