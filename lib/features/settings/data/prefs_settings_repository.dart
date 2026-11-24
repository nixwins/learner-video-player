import 'package:learner_video_player/features/settings/domain/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  static const _nativeLanguageKey = 'native_language_code';

  static const _panelWidthKey = 'translation_panel_width';
  static const _saveDestinationKey = 'save_destination';
  static const _freqAppServerKey = 'freqapp_server';
  static const _freqAppApiKeyKey = 'freqapp_api_key';

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

  @override
  String? get saveDestination => _read(_saveDestinationKey);

  @override
  Future<void> saveSaveDestination(String destination) =>
      _write(_saveDestinationKey, destination);

  @override
  String? get freqAppServer => _read(_freqAppServerKey);

  @override
  Future<void> saveFreqAppServer(String server) =>
      _write(_freqAppServerKey, server);

  @override
  String? get freqAppApiKey => _read(_freqAppApiKeyKey);

  @override
  Future<void> saveFreqAppApiKey(String apiKey) =>
      _write(_freqAppApiKeyKey, apiKey);

  String? _read(String key) {
    final value = _prefs.getString(key);
    return value == null || value.isEmpty ? null : value;
  }

  /// An empty value removes the entry.
  Future<void> _write(String key, String value) =>
      value.isEmpty ? _prefs.remove(key) : _prefs.setString(key, value);
}
