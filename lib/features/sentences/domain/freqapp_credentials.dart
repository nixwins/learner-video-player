/// Where to send sentences and the key that allows it.
class FreqAppCredentials {
  const FreqAppCredentials({required this.baseUrl, required this.apiKey});

  /// Server address without a trailing slash, e.g. `https://example.com`.
  final String baseUrl;
  final String apiKey;

  Uri get sentencesUri => Uri.parse('$baseUrl/api/v1/sentences');
}

/// Cleans up what the user typed as the server address: adds `https://` when
/// no scheme is given, drops trailing slashes and a pasted `/api/v1/sentences`
/// (the app appends it itself). Returns null if the result is not a usable
/// http(s) address.
String? normalizeServerAddress(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  return text
      .replaceAll(RegExp(r'/+$'), '')
      .replaceFirst(RegExp(r'/api/v1(/sentences)?$', caseSensitive: false), '');
}
