final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

const _pathPrefixes = {'shorts', 'embed', 'live', 'v'};

/// Returns the video id of a YouTube link, or null when [input] is not a link
/// to a single YouTube video. This is the only place that knows the URL shapes.
String? youtubeVideoId(String input) {
  var text = input.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  if (!text.contains('://')) text = 'https://$text';

  final uri = Uri.tryParse(text);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? id;
  if (host == 'youtu.be') {
    id = segments.firstOrNull;
  } else if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
    if (segments.length == 1 && segments.first == 'watch') {
      id = uri.queryParameters['v'];
    } else if (segments.length >= 2 && _pathPrefixes.contains(segments[0])) {
      id = segments[1];
    }
  }
  return id != null && _videoId.hasMatch(id) ? id : null;
}
