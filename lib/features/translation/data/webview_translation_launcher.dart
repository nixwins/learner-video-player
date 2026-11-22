import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

/// Opens translations in a separate native webview window
/// (WKWebView on macOS, WebView2 on Windows) and reuses it between lookups.
class WebviewTranslationLauncher implements TranslationLauncher {
  Webview? _window;

  @override
  Future<void> open(Uri uri) async {
    final existing = _window;
    if (existing != null) {
      existing.launch(uri.toString());
      return;
    }

    if (!await WebviewWindow.isWebviewAvailable()) {
      throw StateError(
        'No webview runtime found. On Windows install the Microsoft Edge '
        'WebView2 Runtime.',
      );
    }

    final window = await WebviewWindow.create(
      configuration: const CreateConfiguration(
        windowWidth: 520,
        windowHeight: 700,
        title: 'Translate',
      ),
    );
    _window = window;
    window.onClose.whenComplete(() => _window = null);
    window.launch(uri.toString());
  }
}
