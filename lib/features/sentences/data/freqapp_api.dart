import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:learner_video_player/features/sentences/domain/freqapp_credentials.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';

const _uncertainMessage =
    'The server did not answer in time or the connection dropped, so the '
    'sentence may already be saved. Check the server before saving it again.';

/// Signs that a request never left this computer.
const _neverSentHints = [
  'failed host lookup',
  'connection refused',
  'network is unreachable',
  'no route to host',
  'nodename nor servname',
];

/// The only place that talks to the FreqApp API.
///
/// It never retries: a retry after a dropped connection can create a
/// duplicate, because the server has no uniqueness check on sentences.
class FreqAppApi implements SentenceRepository {
  FreqAppApi({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(minutes: 2);

  final http.Client _client;
  final Duration _timeout;

  @override
  Future<SavedSentence> save(
    SentenceUpload upload,
    FreqAppCredentials credentials,
  ) async {
    final request = http.MultipartRequest('POST', credentials.sentencesUri)
      ..headers['X-API-Key'] = credentials.apiKey
      ..fields['sentence'] = upload.sentence;
    final show = upload.tvShowName;
    if (show != null && show.isNotEmpty) request.fields['tv_show_name'] = show;
    final video = upload.videoPath;
    if (video != null) {
      request.files.add(
        await http.MultipartFile.fromPath('video', video, filename: 'clip.mp4'),
      );
    }

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_timeout);
      return _handle(response, upload);
    } on TimeoutException {
      throw const SentenceSaveException(SaveError.uncertain, _uncertainMessage);
    } on HandshakeException {
      throw SentenceSaveException(
        SaveError.network,
        'A secure connection to ${credentials.baseUrl} could not be made. '
        'Check the server address.',
      );
    } on SocketException catch (e) {
      final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
      if (_neverSentHints.any(text.contains)) {
        throw SentenceSaveException(
          SaveError.network,
          'Cannot connect to ${credentials.baseUrl}. Check the server '
          'address and your internet connection.',
        );
      }
      throw const SentenceSaveException(SaveError.uncertain, _uncertainMessage);
    } on http.ClientException {
      throw const SentenceSaveException(SaveError.uncertain, _uncertainMessage);
    }
  }

  SavedSentence _handle(http.Response response, SentenceUpload upload) {
    final status = response.statusCode;
    if (status == 201) {
      return SavedSentence(
        id: '${_json(response)?['id'] ?? ''}',
        withVideo: upload.videoPath != null,
      );
    }
    final detail = _serverMessage(response);
    switch (status) {
      case 400:
        throw SentenceSaveException(
          SaveError.invalid,
          'The server rejected the sentence (empty, too long, or an '
          'unsupported video type).$detail',
        );
      case 401:
        throw const SentenceSaveException(
          SaveError.unauthorized,
          'The API key is wrong or was revoked. Open Settings and enter a '
          'new one.',
        );
      case 413:
        throw const SentenceSaveException(
          SaveError.tooLarge,
          'The video fragment is larger than 100 MB.',
        );
      case 429:
        throw const SentenceSaveException(
          SaveError.rateLimited,
          'Too many requests (the limit is 30 per minute). Wait a minute and '
          'try again.',
        );
      default:
        throw SentenceSaveException(
          SaveError.server,
          'The server answered with an error (HTTP $status).$detail',
        );
    }
  }

  Map<String, dynamic>? _json(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// A short, safe-to-show message from the server's JSON error body.
  String _serverMessage(http.Response response) {
    final message = _json(response)?['message'];
    final text = switch (message) {
      final String s => s,
      final List<dynamic> l => l.join('; '),
      _ => '',
    }.trim();
    if (text.isEmpty) return '';
    return ' (${text.length > 200 ? '${text.substring(0, 200)}…' : text})';
  }
}
