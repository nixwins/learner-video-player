import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/presentation/clickable_subtitle.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

/// Connects the current subtitle to the clickable widget and wires a word
/// tap to "pause, then translate".
class SubtitleOverlay extends ConsumerWidget {
  const SubtitleOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(translationLauncherProvider).current;
    return ValueListenableBuilder<Uri?>(
      valueListenable: current,
      builder: (context, uri, _) => ClickableSubtitle(
        text: ref.watch(subtitleTextProvider).value ?? '',
        highlightedWord: uri?.queryParameters['text'],
        onWordTap: (word) => _lookUp(ref, word),
      ),
    );
  }

  Future<void> _lookUp(WidgetRef ref, String word) async {
    final gateway = ref.read(playerGatewayProvider);
    final cue = await gateway.currentSubtitleCue();
    ref.read(selectedCueProvider.notifier).select(cue);
    await gateway.pause();
    await ref.read(translateTextProvider)(
      word,
      targetLanguageCode: ref.read(nativeLanguageProvider).code,
    );
  }
}
