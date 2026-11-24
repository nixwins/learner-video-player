import 'dart:io';

/// The `Contents/Resources/bin` folder of the macOS app bundle that runs
/// [executablePath], where the packaged ffmpeg and yt-dlp live. Null when the
/// path is not inside an app bundle.
String? bundledToolsDir(String executablePath) {
  const marker = '.app/Contents/MacOS/';
  final index = executablePath.indexOf(marker);
  if (index < 0) return null;
  return '${executablePath.substring(0, index)}.app/Contents/Resources/bin';
}

/// Folders to look in: tools packaged with the app first, then PATH. GUI apps
/// on macOS do not inherit the shell's PATH, so the usual install locations
/// are searched as well.
List<String> defaultSearchDirs({
  Map<String, String>? environment,
  bool? isWindows,
  String? executablePath,
}) {
  final env = environment ?? Platform.environment;
  final windows = isWindows ?? Platform.isWindows;
  final separator = windows ? ';' : ':';
  final home = env[windows ? 'USERPROFILE' : 'HOME'];
  final bundled = windows
      ? null
      : bundledToolsDir(executablePath ?? Platform.resolvedExecutable);
  return [
    ?bundled,
    ...(env['PATH'] ?? '').split(separator).where((dir) => dir.isNotEmpty),
    if (!windows) ...[
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      if (home != null) '$home/.local/bin',
    ],
    if (windows && env['LOCALAPPDATA'] != null)
      '${env['LOCALAPPDATA']}\\Microsoft\\WinGet\\Links',
  ];
}

/// The full path of the first existing [name] in [searchDirs], or null.
Future<String?> findExecutable(String name, List<String> searchDirs) async {
  final separator = Platform.pathSeparator;
  for (final dir in searchDirs) {
    final path = dir.endsWith(separator) ? '$dir$name' : '$dir$separator$name';
    if (await File(path).exists()) return path;
  }
  return null;
}
