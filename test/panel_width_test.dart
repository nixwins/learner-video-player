import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/panel_width.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

import 'support/fakes.dart';

ProviderContainer _container(FakeSettings settings) {
  final container = ProviderContainer(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('clampPanelWidth', () {
    test('keeps a sensible width unchanged', () {
      expect(clampPanelWidth(420, 1400), 420);
    });

    test('never goes below the minimum', () {
      expect(clampPanelWidth(100, 1400), minPanelWidth);
    });

    test('never takes more than 60% of the window', () {
      expect(clampPanelWidth(2000, 1000), 600);
    });

    test('a tiny window still gets the minimum', () {
      expect(clampPanelWidth(500, 400), minPanelWidth);
    });
  });

  group('translation panel width', () {
    test('defaults when nothing is saved', () {
      final container = _container(FakeSettings());
      expect(container.read(translationPanelWidthProvider), defaultPanelWidth);
    });

    test('restores the saved width', () {
      final container = _container(FakeSettings(null, 500));
      expect(container.read(translationPanelWidthProvider), 500);
    });

    test('resize updates state, persist saves it', () async {
      final settings = FakeSettings();
      final container = _container(settings);
      final notifier = container.read(translationPanelWidthProvider.notifier);

      notifier.resize(480);
      expect(container.read(translationPanelWidthProvider), 480);
      expect(settings.translationPanelWidth, isNull);

      await notifier.persist();
      expect(settings.translationPanelWidth, 480);
    });
  });
}
