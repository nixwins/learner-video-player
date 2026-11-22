import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/youtube/domain/video_resolver.dart';
import 'package:learner_video_player/features/youtube/presentation/open_url_dialog.dart';
import 'package:learner_video_player/features/youtube/presentation/youtube_providers.dart';

import 'support/fakes.dart';

const _link = 'https://www.youtube.com/watch?v=jNQXAC9IVRw';

class _Env {
  _Env() {
    container = ProviderContainer(
      overrides: [
        playerGatewayProvider.overrideWithValue(gateway),
        videoResolverProvider.overrideWithValue(resolver),
      ],
    );
  }

  final gateway = FakePlayerGateway();
  final resolver = FakeVideoResolver();
  late final ProviderContainer container;

  YoutubeLoaderNotifier get loader =>
      container.read(youtubeLoaderProvider.notifier);
  YoutubeLoadState get state => container.read(youtubeLoaderProvider);
}

_Env _env() {
  final env = _Env();
  addTearDown(env.container.dispose);
  return env;
}

void main() {
  group('YoutubeLoaderNotifier', () {
    test('opens the downloaded video with its subtitles', () async {
      final env = _env();

      final result = await env.loader.load(_link);

      expect(env.resolver.requested, [_link]);
      expect(env.gateway.opened, [('/tmp/video.mp4', '/tmp/video.en.srt')]);
      expect(result?.title, 'Me at the zoo');
      expect(result?.hasSubtitles, isTrue);
      expect(env.state.status, YoutubeLoadStatus.idle);
    });

    test('reports a video without subtitles', () async {
      final env = _env();
      env.resolver.result = const ResolvedVideo(
        title: 'Silent film',
        videoPath: '/tmp/video.mp4',
      );

      final result = await env.loader.load(_link);

      expect(result?.hasSubtitles, isFalse);
      expect(env.gateway.opened, [('/tmp/video.mp4', null)]);
    });

    test(
      'rejects text that is not a YouTube link without downloading',
      () async {
        final env = _env();

        final result = await env.loader.load('https://example.com');

        expect(result, isNull);
        expect(env.resolver.requested, isEmpty);
        expect(env.state.status, YoutubeLoadStatus.failed);
      },
    );

    test('keeps the error message when downloading fails', () async {
      final env = _env();
      env.resolver.failure = const VideoResolveException(
        VideoResolveError.failed,
        'yt-dlp is out of date',
      );

      final result = await env.loader.load(_link);

      expect(result, isNull);
      expect(env.gateway.opened, isEmpty);
      expect(env.state.status, YoutubeLoadStatus.failed);
      expect(env.state.message, 'yt-dlp is out of date');
    });

    test(
      'shows progress while downloading and ignores a second request',
      () async {
        final env = _env();
        env.resolver.gate = Completer<void>();

        final first = env.loader.load(_link);
        await Future<void>.delayed(Duration.zero);
        expect(env.state.isLoading, isTrue);
        expect(env.state.fraction, 0.5);
        expect(env.state.title, 'Me at the zoo');

        expect(await env.loader.load(_link), isNull);
        expect(env.resolver.requested, hasLength(1));

        env.resolver.gate!.complete();
        expect((await first)?.title, 'Me at the zoo');
      },
    );

    test('cancel stops the download and opens nothing', () async {
      final env = _env();
      env.resolver.gate = Completer<void>();

      final pending = env.loader.load(_link);
      await Future<void>.delayed(Duration.zero);
      env.loader.cancel();

      expect(await pending, isNull);
      expect(env.gateway.opened, isEmpty);
      expect(env.state.status, YoutubeLoadStatus.idle);
    });
  });

  group('OpenUrlDialog', () {
    Future<_Env> pumpDialog(
      WidgetTester tester,
      List<YoutubeOpenResult?> results,
    ) async {
      final env = _env();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: env.container,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    results.add(await showOpenUrlDialog(context)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('a valid link plays the video and closes the dialog', (
      tester,
    ) async {
      final results = <YoutubeOpenResult?>[];
      final env = await pumpDialog(tester, results);

      await tester.enterText(find.byType(TextField), _link);
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(env.gateway.opened, hasLength(1));
      expect(find.byType(OpenUrlDialog), findsNothing);
      expect(results.single?.title, 'Me at the zoo');
    });

    testWidgets('a wrong link shows an error and stays open', (tester) async {
      final results = <YoutubeOpenResult?>[];
      final env = await pumpDialog(tester, results);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(find.textContaining('does not look like a link'), findsOneWidget);
      expect(find.byType(OpenUrlDialog), findsOneWidget);
      expect(env.resolver.requested, isEmpty);
    });

    testWidgets('shows download progress and can be cancelled', (tester) async {
      final results = <YoutubeOpenResult?>[];
      final env = await pumpDialog(tester, results);
      env.resolver.gate = Completer<void>();

      await tester.enterText(find.byType(TextField), _link);
      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Downloading'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);

      await tester.tap(find.text('Cancel download'));
      await tester.pumpAndSettle();

      expect(env.gateway.opened, isEmpty);
      expect(find.text('Cancel download'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Close dismisses the dialog', (tester) async {
      final results = <YoutubeOpenResult?>[];
      await pumpDialog(tester, results);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(OpenUrlDialog), findsNothing);
      expect(results, [null]);
    });
  });
}
