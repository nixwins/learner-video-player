import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/settings/data/prefs_settings_repository.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

ProviderContainer _container(FakeSettings settings) {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('normalizeServerAddress', () {
    for (final (input, expected) in [
      ('https://freq.example.com', 'https://freq.example.com'),
      ('freq.example.com', 'https://freq.example.com'),
      ('  https://freq.example.com/  ', 'https://freq.example.com'),
      ('https://freq.example.com///', 'https://freq.example.com'),
      ('http://localhost:3000', 'http://localhost:3000'),
      ('https://example.com/prefix', 'https://example.com/prefix'),
      ('http://localhost:6677/api/v1/sentences', 'http://localhost:6677'),
      ('http://localhost:6677/api/v1/sentences/', 'http://localhost:6677'),
      ('http://localhost:6677/api/v1', 'http://localhost:6677'),
      ('https://example.com/app/api/v1/sentences', 'https://example.com/app'),
      ('', null),
      ('   ', null),
      ('ftp://example.com', null),
      ('https://', null),
    ]) {
      test('"$input" -> $expected', () {
        expect(normalizeServerAddress(input), expected);
      });
    }
  });

  group('FreqAppSettingsNotifier', () {
    test('is not configured at first', () {
      final container = _container(FakeSettings());
      expect(container.read(freqAppSettingsProvider).isConfigured, isFalse);
      expect(container.read(freqAppSettingsProvider).credentials, isNull);
    });

    test('restores saved values', () {
      final container = _container(
        FakeSettings(null, null, 'https://freq.example.com', 'tvs_abc'),
      );
      final credentials = container.read(freqAppSettingsProvider).credentials;
      expect(credentials?.baseUrl, 'https://freq.example.com');
      expect(credentials?.apiKey, 'tvs_abc');
    });

    test('save cleans up and persists both values', () async {
      final settings = FakeSettings();
      final container = _container(settings);

      await container
          .read(freqAppSettingsProvider.notifier)
          .save(server: ' freq.example.com/ ', apiKey: '  tvs_abc  ');

      expect(settings.freqAppServer, 'https://freq.example.com');
      expect(settings.freqAppApiKey, 'tvs_abc');
      expect(container.read(freqAppSettingsProvider).isConfigured, isTrue);
    });

    test('replacing the key takes effect immediately', () async {
      final settings = FakeSettings(
        null,
        null,
        'https://freq.example.com',
        'tvs_old',
      );
      final container = _container(settings);

      await container
          .read(freqAppSettingsProvider.notifier)
          .save(server: 'https://freq.example.com', apiKey: 'tvs_new');

      expect(
        container.read(freqAppSettingsProvider).credentials?.apiKey,
        'tvs_new',
      );
      expect(settings.freqAppApiKey, 'tvs_new');
    });

    test('a blank key leaves it not configured', () {
      final container = _container(
        FakeSettings(null, null, 'https://freq.example.com', '   '),
      );
      expect(container.read(freqAppSettingsProvider).isConfigured, isFalse);
    });
  });

  group('PrefsSettingsRepository', () {
    test('stores and replaces the key and address', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(repository.freqAppApiKey, isNull);

      await repository.saveFreqAppServer('https://freq.example.com');
      await repository.saveFreqAppApiKey('tvs_one');
      expect(repository.freqAppApiKey, 'tvs_one');

      await repository.saveFreqAppApiKey('tvs_two');
      expect(repository.freqAppApiKey, 'tvs_two');
      expect(repository.freqAppServer, 'https://freq.example.com');
    });

    test('saving an empty value removes it', () async {
      SharedPreferences.setMockInitialValues({'freqapp_api_key': 'tvs_one'});
      final repository = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );

      await repository.saveFreqAppApiKey('');

      expect(repository.freqAppApiKey, isNull);
    });
  });
}
