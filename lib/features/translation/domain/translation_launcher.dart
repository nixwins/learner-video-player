import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum TranslationLoadState { loading, ready, failed }

/// Shows a translation page inside the app window.
///
/// Pragmatic note: [buildView] returns a Flutter widget because the web engine
/// owns a native view; everything else is plain Dart.
abstract interface class TranslationLauncher {
  Future<void> open(Uri uri);

  /// Loads the current page again, for example after a network failure.
  Future<void> reload();

  void close();

  /// The page being shown, or null while the panel is closed.
  ValueListenable<Uri?> get current;

  ValueListenable<TranslationLoadState> get loadState;

  Widget buildView();
}
