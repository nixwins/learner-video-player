import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_page.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_dialog.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

import 'support/fakes.dart';

Future<FakeSettings> _pumpDialog(
  WidgetTester tester, {
  FakeSettings? settings,
  List<bool>? results,
}) async {
  final repository = settings ?? FakeSettings('kk');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final saved = await showSettingsDialog(context);
              results?.add(saved);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repository;
}

Finder get _server => find.byType(TextField).at(0);
Finder get _key => find.byType(TextField).at(1);

void main() {
  testWidgets('starts empty on first use', (tester) async {
    await _pumpDialog(tester);

    expect(tester.widget<TextField>(_server).controller!.text, isEmpty);
    expect(tester.widget<TextField>(_key).controller!.text, isEmpty);
  });

  testWidgets('saves a new address and key', (tester) async {
    final results = <bool>[];
    final settings = await _pumpDialog(tester, results: results);

    await tester.enterText(_server, 'https://freq.example.com/');
    await tester.enterText(_key, '  tvs_abc123 ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(settings.freqAppServer, 'https://freq.example.com');
    expect(settings.freqAppApiKey, 'tvs_abc123');
    expect(results, [true]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows the saved values so the key can be replaced', (
    tester,
  ) async {
    final results = <bool>[];
    final settings = await _pumpDialog(
      tester,
      settings: FakeSettings('kk', null, 'https://freq.example.com', 'tvs_old'),
      results: results,
    );

    expect(
      tester.widget<TextField>(_server).controller!.text,
      'https://freq.example.com',
    );
    expect(tester.widget<TextField>(_key).controller!.text, 'tvs_old');

    await tester.enterText(_key, 'tvs_new');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(settings.freqAppApiKey, 'tvs_new');
    expect(settings.freqAppServer, 'https://freq.example.com');
    expect(results, [true]);
  });

  testWidgets('hides the key until asked to show it', (tester) async {
    await _pumpDialog(
      tester,
      settings: FakeSettings('kk', null, 'https://freq.example.com', 'tvs_x'),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Show key'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Hide key'), findsOneWidget);
  });

  testWidgets('asks for both fields and saves nothing when empty', (
    tester,
  ) async {
    final results = <bool>[];
    final settings = await _pumpDialog(tester, results: results);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enter an address'), findsOneWidget);
    expect(find.text('Enter the API key'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(settings.freqAppApiKey, isNull);
    expect(results, isEmpty);
  });

  testWidgets('rejects an address that is not http(s)', (tester) async {
    final settings = await _pumpDialog(tester);

    await tester.enterText(_server, 'ftp://example.com');
    await tester.enterText(_key, 'tvs_abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enter an address'), findsOneWidget);
    expect(settings.freqAppServer, isNull);
  });

  testWidgets('Cancel keeps the old values', (tester) async {
    final results = <bool>[];
    final settings = await _pumpDialog(
      tester,
      settings: FakeSettings('kk', null, 'https://freq.example.com', 'tvs_old'),
      results: results,
    );

    await tester.enterText(_key, 'tvs_other');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(settings.freqAppApiKey, 'tvs_old');
    expect(results, [false]);
  });

  testWidgets('the gear button in the player opens the settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerGatewayProvider.overrideWithValue(FakePlayerGateway()),
          translationLauncherProvider.overrideWithValue(
            FakeTranslationLauncher(),
          ),
          settingsRepositoryProvider.overrideWithValue(FakeSettings('kk')),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const PlayerPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('FreqApp'), findsOneWidget);
    expect(find.text('Server address'), findsOneWidget);
    expect(find.text('API key'), findsOneWidget);
  });
}
