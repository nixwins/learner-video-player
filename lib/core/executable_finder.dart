import 'dart:io';

/// Folders to look in. GUI apps on macOS do not inherit the shell's PATH, so
/// the usual install locations are searched as well.
List<String> defaultSearchDirs({
  Map<String, String>? environment,
  bool? isWindows,
}) {
  final env = environment ?? Platform.environment;
  final windows = isWindows ?? Platform.isWindows;
  final separator = windows ? ';' : ':';
  final home = env[windows ? 'USERPROFILE' : 'HOME'];
  return [
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
