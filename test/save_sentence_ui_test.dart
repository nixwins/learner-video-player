import 'dart:io';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_page.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/player/presentation/subtitle_overlay.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';
import 'package:learner_video_player/features/sentences/presentation/sentence_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

import 'support/fakes.dart';

FakeSettings _serverWithoutKey() =>
    FakeSettings('kk')..saveDestination = 'server';

class _Harness {
  _Harness({FakeSettings? settings})
    : settings =
          settings ??
          FakeSettings('kk', null, 'https://freq.example.com', 'tvs_secret');

  final gateway = FakePlayerGateway();
  final launcher = FakeTranslationLauncher();
  final repository = FakeSentenceRepository();
  final cutter = FakeClipCutter();
  final library = FakeSentenceLibrary();
  final FakeSettings settings;
}

Future<_Harness> _pump(WidgetTester tester, {FakeSettings? settings}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final harness = _Harness(settings: settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerGatewayProvider.overrideWithValue(harness.gateway),
        translationLauncherProvider.overrideWithValue(harness.launcher),
        settingsRepositoryProvider.overrideWithValue(harness.settings),
        sentenceRepositoryProvider.overrideWithValue(harness.repository),
        clipCutterProvider.overrideWithValue(harness.cutter),
        sentenceLibraryProvider.overrideWithValue(harness.library),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const PlayerPage()),
    ),
  );
  await tester.pump();
  return harness;
}

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(SubtitleOverlay),
      matching: find.text('government'),
    ),
  );
  await tester.pump();
}

Finder get _saveButton => find.widgetWithText(FilledButton, 'Save');

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

void main() {
  testWidgets('Save sends the sentence and just its video fragment', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await _openPanel(tester);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(harness.cutter.cuts.single.source, '/videos/Friends S01E02.mp4');
    expect(harness.cutter.cuts.single.from, const Duration(milliseconds: 9750));
    expect(harness.cutter.cuts.single.to, const Duration(milliseconds: 13300));
    expect(harness.cutter.cuts.single.audio, 1);

    final (upload, credentials) = harness.repository.uploads.single;
    expect(upload.sentence, 'I know the government');
    expect(upload.tvShowName, 'Friends S01E02');
    expect(upload.videoPath, '/tmp/clip.mp4');
    expect(credentials.baseUrl, 'https://freq.example.com');
    expect(credentials.apiKey, 'tvs_secret');
    expect(harness.cutter.discarded, 1);

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Saved with its video fragment.'), findsOneWidget);
  });

  testWidgets('a saved sentence cannot be saved again', (tester) async {
    final harness = await _pump(tester);
    await _openPanel(tester);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(_saveButton, findsNothing);
    final saved = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Saved'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(saved.onPressed, isNull);
    expect(harness.repository.uploads, hasLength(1));
  });

  testWidgets('shows progress while saving', (tester) async {
    final harness = await _pump(tester);
    harness.repository.gate = Completer<void>();
    await _openPanel(tester);

    await tester.tap(_saveButton);
    await tester.pump();
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    harness.repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('a sentence with unknown timing is saved without a video', (
    tester,
  ) async {
    final harness = await _pump(tester);
    harness.gateway.cue = const SubtitleCue(text: 'I know the government');
    await _openPanel(tester);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(harness.cutter.cuts, isEmpty);
    expect(harness.repository.uploads.single.$1.videoPath, isNull);
    expect(find.textContaining('Saved without a video'), findsOneWidget);
  });

  testWidgets('an error is shown and saving can be tried again', (
    tester,
  ) async {
    final harness = await _pump(tester);
    harness.repository.failure = const SentenceSaveException(
      SaveError.unauthorized,
      'The API key is wrong or was revoked.',
    );
    await _openPanel(tester);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('The API key is wrong or was revoked.'), findsOneWidget);
    expect(_saveButton, findsOneWidget);
    expect(harness.cutter.discarded, 1);

    harness.repository.failure = null;
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('The API key is wrong or was revoked.'), findsNothing);
    expect(harness.repository.uploads, hasLength(2));
  });

  testWidgets('a cutting problem such as missing ffmpeg is shown', (
    tester,
  ) async {
    final harness = await _pump(tester);
    harness.cutter.failure = const ClipException('ffmpeg is not installed');
    await _openPanel(tester);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('ffmpeg is not installed'), findsOneWidget);
    expect(harness.repository.uploads, isEmpty);
  });

  group('without FreqApp settings', () {
    testWidgets('Save asks for them first, then saves', (tester) async {
      final harness = await _pump(tester, settings: _serverWithoutKey());
      await _openPanel(tester);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(harness.repository.uploads, isEmpty);

      await tester.enterText(find.byType(TextField).at(0), 'freq.example.com');
      await tester.enterText(find.byType(TextField).at(1), 'tvs_typed');
      await tester.tap(_inDialog('Save'));
      await tester.pumpAndSettle();

      final (_, credentials) = harness.repository.uploads.single;
      expect(credentials.baseUrl, 'https://freq.example.com');
      expect(credentials.apiKey, 'tvs_typed');
      expect(harness.settings.freqAppApiKey, 'tvs_typed');
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('cancelling the settings sends nothing', (tester) async {
      final harness = await _pump(tester, settings: _serverWithoutKey());
      await _openPanel(tester);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      await tester.tap(_inDialog('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.repository.uploads, isEmpty);
      expect(_saveButton, findsOneWidget);
    });
  });

  group('saving on this computer', () {
    testWidgets('Save keeps the sentence locally without any server', (
      tester,
    ) async {
      final harness = await _pump(tester, settings: FakeSettings('kk'));
      await _openPanel(tester);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.repository.uploads, isEmpty);
      expect(harness.library.added.single.text, 'I know the government');
      expect(harness.library.added.single.hasVideo, isTrue);
      expect(find.text('Saved'), findsOneWidget);
      expect(
        find.text('Saved on this computer with its video fragment.'),
        findsOneWidget,
      );
    });

    testWidgets('a storage problem is shown', (tester) async {
      final harness = await _pump(tester, settings: FakeSettings('kk'));
      harness.library.failure = const FileSystemException('disk full');
      await _openPanel(tester);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save on this computer'), findsOne);
      expect(_saveButton, findsOneWidget);
    });
  });
}
