import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/languages.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/save_destination.dart';
import 'package:learner_video_player/features/settings/domain/settings_repository.dart';

/// Wired in `main.dart`.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('Override settingsRepositoryProvider'),
);

class NativeLanguageNotifier extends Notifier<Language> {
  @override
  Language build() =>
      languageByCode(ref.watch(settingsRepositoryProvider).nativeLanguageCode);

  Future<void> select(String code) async {
    state = languageByCode(code);
    await ref
        .read(settingsRepositoryProvider)
        .saveNativeLanguageCode(state.code);
  }
}

final nativeLanguageProvider =
    NotifierProvider<NativeLanguageNotifier, Language>(
      NativeLanguageNotifier.new,
    );

class FreqAppSettings {
  const FreqAppSettings({this.server = '', this.apiKey = ''});

  final String server;
  final String apiKey;

  /// Ready to use: a valid address and a non-empty key.
  FreqAppCredentials? get credentials {
    final baseUrl = normalizeServerAddress(server);
    final key = apiKey.trim();
    if (baseUrl == null || key.isEmpty) return null;
    return FreqAppCredentials(baseUrl: baseUrl, apiKey: key);
  }

  bool get isConfigured => credentials != null;
}

class FreqAppSettingsNotifier extends Notifier<FreqAppSettings> {
  @override
  FreqAppSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    return FreqAppSettings(
      server: repository.freqAppServer ?? '',
      apiKey: repository.freqAppApiKey ?? '',
    );
  }

  /// Replaces both values; the next save uses them without a restart.
  Future<void> save({required String server, required String apiKey}) async {
    final repository = ref.read(settingsRepositoryProvider);
    final cleanServer = normalizeServerAddress(server) ?? server.trim();
    final cleanKey = apiKey.trim();
    await repository.saveFreqAppServer(cleanServer);
    await repository.saveFreqAppApiKey(cleanKey);
    state = FreqAppSettings(server: cleanServer, apiKey: cleanKey);
  }
}

final freqAppSettingsProvider =
    NotifierProvider<FreqAppSettingsNotifier, FreqAppSettings>(
      FreqAppSettingsNotifier.new,
    );

/// Where Save puts sentences. Until the user chooses, it is the server for
/// someone who already set it up, and this computer for everyone else.
class SaveDestinationNotifier extends Notifier<SaveDestination> {
  @override
  SaveDestination build() {
    final stored = SaveDestination.fromStorage(
      ref.read(settingsRepositoryProvider).saveDestination,
    );
    if (stored != null) return stored;
    return ref.read(freqAppSettingsProvider).isConfigured
        ? SaveDestination.server
        : SaveDestination.local;
  }

  Future<void> select(SaveDestination destination) async {
    state = destination;
    await ref
        .read(settingsRepositoryProvider)
        .saveSaveDestination(destination.storageValue);
  }
}

final saveDestinationProvider =
    NotifierProvider<SaveDestinationNotifier, SaveDestination>(
      SaveDestinationNotifier.new,
    );
