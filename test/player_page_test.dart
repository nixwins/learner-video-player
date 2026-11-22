import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_page.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/subtitle_overlay.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/translation/presentation/translation_panel.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

import 'support/fakes.dart';

Finder _inSubtitle(String word) => find.descendant(
  of: find.byType(SubtitleOverlay),
  matching: find.text(word),
);

Finder _inPanel(String word) => find.descendant(
  of: find.byType(TranslationPanel),
  matching: find.text(word),
);

class _Harness {
  final gateway = FakePlayerGateway();
  final launcher = FakeTranslationLauncher();
}

Future<_Harness> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final harness = _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerGatewayProvider.overrideWithValue(harness.gateway),
        translationLauncherProvider.overrideWithValue(harness.launcher),
        settingsRepositoryProvider.overrideWithValue(FakeSettings('kk')),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const PlayerPage()),
    ),
  );
  await tester.pump();
  return harness;
}

void main() {
  testWidgets('the translation panel is hidden until a word is clicked', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(TranslationPanel), findsNothing);
  });

  testWidgets('clicking a word pauses the video and opens the side panel', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(_inSubtitle('government'));
    await tester.pump();

    expect(harness.gateway.pauseCalls, 1);
    final uri = harness.launcher.opened.single;
    expect(uri.queryParameters['text'], 'government');
    expect(uri.queryParameters['sl'], 'en');
    expect(uri.queryParameters['tl'], 'kk');
    expect(find.byType(TranslationPanel), findsOneWidget);
    expect(find.byKey(const Key('fake-web-view')), findsOneWidget);
  });

  testWidgets('the close button hides the panel', (tester) async {
    await _pump(tester);
    await tester.tap(_inSubtitle('government'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.byType(TranslationPanel), findsNothing);
  });

  testWidgets('Escape hides the panel', (tester) async {
    await _pump(tester);
    await tester.tap(_inSubtitle('government'));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byType(TranslationPanel), findsNothing);
  });

  testWidgets('Space toggles playback', (tester) async {
    final harness = await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(harness.gateway.togglePlayCalls, 1);
  });

  group('sentence panel', () {
    testWidgets('shows the full sentence with clickable words', (tester) async {
      await _pump(tester);
      await tester.tap(_inSubtitle('government'));
      await tester.pump();

      for (final word in ['I', 'know', 'the', 'government']) {
        expect(_inPanel(word), findsOneWidget);
      }
    });

    testWidgets('Translate sentence translates the whole sentence', (
      tester,
    ) async {
      final harness = await _pump(tester);
      await tester.tap(_inSubtitle('government'));
      await tester.pump();

      await tester.tap(find.text('Translate sentence'));
      await tester.pump();

      expect(
        harness.launcher.opened.last.queryParameters['text'],
        'I know the government',
      );
      expect(harness.launcher.opened.last.queryParameters['tl'], 'kk');
    });

    testWidgets('clicking another word in the panel translates it', (
      tester,
    ) async {
      final harness = await _pump(tester);
      await tester.tap(_inSubtitle('government'));
      await tester.pump();
      final pausesBefore = harness.gateway.pauseCalls;

      await tester.tap(_inPanel('know'));
      await tester.pump();

      expect(harness.launcher.opened.last.queryParameters['text'], 'know');
      expect(harness.gateway.pauseCalls, pausesBefore + 1);
    });

    testWidgets('Play again replays the sentence from just before its start', (
      tester,
    ) async {
      final harness = await _pump(tester);
      await tester.tap(_inSubtitle('government'));
      await tester.pump();

      await tester.tap(find.text('Play again'));
      await tester.pump();

      expect(harness.gateway.playedRanges, [
        (const Duration(milliseconds: 9750), const Duration(seconds: 13)),
      ]);
    });

    testWidgets('Play again is disabled when the timing is unknown', (
      tester,
    ) async {
      final harness = await _pump(tester);
      harness.gateway.cue = const SubtitleCue(text: 'I know the government');
      await tester.tap(_inSubtitle('government'));
      await tester.pump();

      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Play again'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('without a known sentence only the word is shown', (
      tester,
    ) async {
      final harness = await _pump(tester);
      harness.gateway.cue = null;
      await tester.tap(_inSubtitle('government'));
      await tester.pump();

      expect(_inPanel('government'), findsOneWidget);
      expect(find.text('Translate sentence'), findsNothing);
    });
  });
}
