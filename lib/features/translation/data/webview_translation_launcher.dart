import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders translations in an embedded web view (WKWebView on macOS) and
/// reuses one controller for every lookup.
class WebviewTranslationLauncher implements TranslationLauncher {
  WebviewTranslationLauncher() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _loadState.value = TranslationLoadState.loading,
          onPageFinished: (_) {
            if (_loadState.value != TranslationLoadState.failed) {
              _loadState.value = TranslationLoadState.ready;
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _loadState.value = TranslationLoadState.failed;
            }
          },
        ),
      );
  }

  late final WebViewController _controller;
  final _current = ValueNotifier<Uri?>(null);
  final _loadState = ValueNotifier(TranslationLoadState.loading);

  @override
  ValueListenable<Uri?> get current => _current;

  @override
  ValueListenable<TranslationLoadState> get loadState => _loadState;

  @override
  Future<void> open(Uri uri) {
    _current.value = uri;
    return _load(uri);
  }

  @override
  Future<void> reload() async {
    final uri = _current.value;
    if (uri != null) await _load(uri);
  }

  Future<void> _load(Uri uri) {
    _loadState.value = TranslationLoadState.loading;
    return _controller.loadRequest(uri);
  }

  @override
  void close() => _current.value = null;

  @override
  Widget buildView() => WebViewWidget(controller: _controller);
}
