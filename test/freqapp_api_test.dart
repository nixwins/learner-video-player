import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:learner_video_player/features/sentences/data/freqapp_api.dart';
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';

const _credentials = FreqAppCredentials(
  baseUrl: 'https://freq.example.com',
  apiKey: 'tvs_secret_key',
);

class _Captured {
  late http.BaseRequest request;
  late String body;
}

void main() {
  late Directory tmp;
  late File clip;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('api_test');
    clip = File('${tmp.path}/clip.mp4')..writeAsBytesSync([1, 2, 3, 4]);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  FreqAppApi apiAnswering(
    int status, {
    String body = '{}',
    _Captured? captured,
  }) {
    return FreqAppApi(
      client: MockClient.streaming((request, bodyStream) async {
        captured?.request = request;
        captured?.body = latin1.decode(await bodyStream.toBytes());
        return http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  Future<void> expectError(
    Future<SavedSentence> future,
    SaveError error, {
    String? mentions,
  }) => expectLater(
    future,
    throwsA(
      isA<SentenceSaveException>()
          .having((e) => e.error, 'error', error)
          .having((e) => e.message, 'message', contains(mentions ?? '')),
    ),
  );

  test('posts the sentence, show name and clip with the API key', () async {
    final captured = _Captured();
    final api = apiAnswering(
      201,
      body: '{"id":"abc-123","sentence":"Hi"}',
      captured: captured,
    );

    final saved = await api.save(
      SentenceUpload(
        sentence: "I don't know what you mean.",
        tvShowName: 'Friends',
        videoPath: clip.path,
      ),
      _credentials,
    );

    expect(saved.id, 'abc-123');
    expect(saved.withVideo, isTrue);
    expect(captured.request.method, 'POST');
    expect(
      captured.request.url.toString(),
      'https://freq.example.com/api/v1/sentences',
    );
    expect(captured.request.headers['X-API-Key'], 'tvs_secret_key');
    expect(
      captured.request.headers['content-type'],
      startsWith('multipart/form-data'),
    );
    expect(captured.body, contains('name="sentence"'));
    expect(captured.body, contains("I don't know what you mean."));
    expect(captured.body, contains('name="tv_show_name"'));
    expect(captured.body, contains('Friends'));
    expect(captured.body, contains('name="video"'));
    expect(captured.body, contains('filename="clip.mp4"'));
  });

  test('omits the video and show name when there are none', () async {
    final captured = _Captured();
    final api = apiAnswering(201, body: '{"id":"x"}', captured: captured);

    final saved = await api.save(
      const SentenceUpload(sentence: 'Hello'),
      _credentials,
    );

    expect(saved.withVideo, isFalse);
    expect(captured.body, isNot(contains('name="video"')));
    expect(captured.body, isNot(contains('name="tv_show_name"')));
  });

  test('still succeeds when a 201 answer has an unexpected body', () async {
    final api = apiAnswering(201, body: 'not json');
    final saved = await api.save(
      const SentenceUpload(sentence: 'Hello'),
      _credentials,
    );
    expect(saved.id, isEmpty);
  });

  group('error answers', () {
    Future<SavedSentence> save(FreqAppApi api) =>
        api.save(const SentenceUpload(sentence: 'Hello'), _credentials);

    test('400 is an invalid sentence, with the server explanation', () {
      return expectError(
        save(apiAnswering(400, body: '{"message":["sentence too long"]}')),
        SaveError.invalid,
        mentions: 'sentence too long',
      );
    });

    test('401 asks for a new key and never repeats the key', () async {
      final api = apiAnswering(401);
      try {
        await save(api);
        fail('should throw');
      } on SentenceSaveException catch (e) {
        expect(e.error, SaveError.unauthorized);
        expect(e.message, contains('Settings'));
        expect(e.message, isNot(contains('tvs_secret_key')));
      }
    });

    test('413 is a too large video', () {
      return expectError(save(apiAnswering(413)), SaveError.tooLarge);
    });

    test('429 asks to wait', () {
      return expectError(
        save(apiAnswering(429)),
        SaveError.rateLimited,
        mentions: '30 per minute',
      );
    });

    test('other codes are server errors', () {
      return expectError(
        save(apiAnswering(502, body: '<html>Bad gateway</html>')),
        SaveError.server,
        mentions: 'HTTP 502',
      );
    });

    test('a very long server message is shortened', () async {
      final api = apiAnswering(500, body: jsonEncode({'message': 'x' * 500}));
      try {
        await save(api);
        fail('should throw');
      } on SentenceSaveException catch (e) {
        expect(e.message.length, lessThan(300));
      }
    });
  });

  group('connection problems', () {
    Future<SavedSentence> save(FreqAppApi api) =>
        api.save(const SentenceUpload(sentence: 'Hello'), _credentials);

    test('a timeout is reported as uncertain, never retried', () async {
      var calls = 0;
      final api = FreqAppApi(
        timeout: const Duration(milliseconds: 50),
        client: MockClient.streaming((request, body) {
          calls++;
          return Completer<http.StreamedResponse>().future;
        }),
      );
      await expectError(
        save(api),
        SaveError.uncertain,
        mentions: 'Check the server',
      );
      expect(calls, 1);
    });

    test('a dropped connection is reported as uncertain', () {
      final api = FreqAppApi(
        client: MockClient.streaming(
          (request, body) =>
              throw http.ClientException('Connection closed early'),
        ),
      );
      return expectError(save(api), SaveError.uncertain);
    });

    test('an unknown host is reported as a network problem', () {
      final api = FreqAppApi(
        client: MockClient.streaming(
          (request, body) => throw const SocketException(
            'Failed host lookup: freq.example.com',
          ),
        ),
      );
      return expectError(
        save(api),
        SaveError.network,
        mentions: 'https://freq.example.com',
      );
    });

    test('a TLS failure is reported as a network problem', () {
      final api = FreqAppApi(
        client: MockClient.streaming(
          (request, body) => throw const HandshakeException('bad cert'),
        ),
      );
      return expectError(save(api), SaveError.network);
    });
  });
}
