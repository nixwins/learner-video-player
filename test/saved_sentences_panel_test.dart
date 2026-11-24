import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_page.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/presentation/saved_sentences_panel.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

import 'support/fakes.dart';

class _Harness {
  final gateway = FakePlayerGateway();
  final launcher = FakeTranslationLauncher();
  final library = FakeSentenceLibrary();
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
        sentenceLibraryProvider.overrideWithValue(harness.library),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const PlayerPage()),
    ),
  );
  await tester.pump();
  return harness;
}

Future<void> _addSaved(
  _Harness harness, {
  String text = 'I know the government',
  bool withVideo = true,
}) => harness.library.add(
  text: text,
  showName: 'Friends',
  clip: withVideo
      ? Clip(path: '/tmp/x.mp4', bytes: 1, discard: () async {})
      : null,
  clipDuration: const Duration(seconds: 3),
);

Finder get _bookmarks => find.byTooltip('Saved sentences');

void main() {
  testWidgets('the bookmarks button opens and closes the list', (tester) async {
    await _pump(tester);
    expect(find.byType(SavedSentencesPanel), findsNothing);

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();
    expect(find.byType(SavedSentencesPanel), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();
    expect(find.byType(SavedSentencesPanel), findsNothing);
  });

  testWidgets('lists the saved sentences with their show and date', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await _addSaved(harness, text: 'first one');
    await _addSaved(harness, text: 'second one');

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();

    expect(find.text('Saved sentences · 2'), findsOneWidget);
    expect(find.text('first one'), findsOneWidget);
    expect(find.text('2026-11-24 · Friends'), findsNWidgets(2));
    final top = tester.getTopLeft(find.text('second one')).dy;
    final bottom = tester.getTopLeft(find.text('first one')).dy;
    expect(top, lessThan(bottom));
  });

  testWidgets('clicking a sentence plays its video with the subtitle', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await _addSaved(harness);

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();
    await tester.tap(find.text('I know the government'));
    await tester.pumpAndSettle();

    expect(harness.gateway.opened.single, (
      '/library/sentence-1.mp4',
      '/library/sentence-1.srt',
    ));
    expect(harness.gateway.openedTitles.single, 'Friends');
    expect(find.text('Drop a video here'), findsNothing);
  });

  testWidgets('a sentence without a video cannot be played', (tester) async {
    final harness = await _pump(tester);
    await _addSaved(harness, withVideo: false);

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();

    expect(find.textContaining('no video'), findsOneWidget);
    await tester.tap(find.text('I know the government'));
    await tester.pumpAndSettle();
    expect(harness.gateway.opened, isEmpty);
  });

  testWidgets('delete asks first and then removes the sentence', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await _addSaved(harness);
    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.library.removed, isEmpty);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(harness.library.removed, [1]);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('opening a translation replaces the list, Esc closes both', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PlayerPage),
        matching: find.text('government'),
      ),
    );
    await tester.pump();
    expect(find.byType(SavedSentencesPanel), findsNothing);
    expect(harness.launcher.current.value, isNotNull);

    await tester.tap(_bookmarks);
    await tester.pumpAndSettle();
    expect(find.byType(SavedSentencesPanel), findsOneWidget);
    expect(harness.launcher.current.value, isNull);
  });
}
