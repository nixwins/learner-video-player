/// Where "Save" puts a sentence.
enum SaveDestination {
  /// Uploaded to the FreqApp server.
  server,

  /// Kept on this computer and listed in the app.
  local;

  /// The value kept in settings.
  String get storageValue => name;

  static SaveDestination? fromStorage(String? value) {
    for (final destination in values) {
      if (destination.name == value) return destination;
    }
    return null;
  }
}
