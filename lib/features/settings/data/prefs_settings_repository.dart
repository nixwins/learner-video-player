import 'package:learner_video_player/features/settings/domain/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  static const _nativeLanguageKey = 'native_language_code';

  static const _panelWidthKey = 'translation_panel_width';

  final SharedPreferences _prefs;

  @override
  String? get nativeLanguageCode => _prefs.getString(_nativeLanguageKey);

  @override
  Future<void> saveNativeLanguageCode(String code) =>
      _prefs.setString(_nativeLanguageKey, code);

  @override
  double? get translationPanelWidth => _prefs.getDouble(_panelWidthKey);

  @override
  Future<void> saveTranslationPanelWidth(double width) =>
      _prefs.setDouble(_panelWidthKey, width);
}
