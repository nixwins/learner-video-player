import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/languages.dart';
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
