import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/panel_width.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';
import 'package:learner_video_player/features/translation/domain/translate_text.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

/// Wired in `main.dart`.
final translationLauncherProvider = Provider<TranslationLauncher>(
  (ref) => throw UnimplementedError('Override translationLauncherProvider'),
);

final translateTextProvider = Provider<TranslateText>(
  (ref) => TranslateText(ref.watch(translationLauncherProvider)),
);

/// The subtitle sentence the user is currently looking up.
class SelectedCueNotifier extends Notifier<SubtitleCue?> {
  @override
  SubtitleCue? build() => null;

  void select(SubtitleCue? cue) => state = cue;
}

final selectedCueProvider = NotifierProvider<SelectedCueNotifier, SubtitleCue?>(
  SelectedCueNotifier.new,
);

/// Width of the translation side panel. [resize] is called continuously while
/// dragging; [persist] once when the drag ends.
class TranslationPanelWidthNotifier extends Notifier<double> {
  @override
  double build() =>
      ref.watch(settingsRepositoryProvider).translationPanelWidth ??
      defaultPanelWidth;

  void resize(double width) => state = width;

  Future<void> persist() =>
      ref.read(settingsRepositoryProvider).saveTranslationPanelWidth(state);
}

final translationPanelWidthProvider =
    NotifierProvider<TranslationPanelWidthNotifier, double>(
      TranslationPanelWidthNotifier.new,
    );
