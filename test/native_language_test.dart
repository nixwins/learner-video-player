import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/languages.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';

import 'support/fakes.dart';

ProviderContainer _container(FakeSettings settings) {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to the first supported language', () {
    final container = _container(FakeSettings());
    expect(container.read(nativeLanguageProvider), supportedLanguages.first);
  });

  test('restores a saved language', () {
    final container = _container(FakeSettings('ru'));
    expect(container.read(nativeLanguageProvider).code, 'ru');
  });

  test('unknown saved code falls back to default', () {
    expect(languageByCode('xx'), supportedLanguages.first);
  });

  test('select updates state and persists', () async {
    final settings = FakeSettings();
    final container = _container(settings);
    await container.read(nativeLanguageProvider.notifier).select('tr');
    expect(container.read(nativeLanguageProvider).code, 'tr');
    expect(settings.nativeLanguageCode, 'tr');
  });
}
