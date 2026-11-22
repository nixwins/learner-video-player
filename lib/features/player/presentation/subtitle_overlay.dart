import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
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
    return ClickableSubtitle(
      text: ref.watch(subtitleTextProvider).value ?? '',
      onWordTap: (word) => _lookUp(ref, word),
    );
  }

  Future<void> _lookUp(WidgetRef ref, String word) async {
    await ref.read(playerGatewayProvider).pause();
    await ref.read(translateWordProvider)(
      word,
      targetLanguageCode: ref.read(nativeLanguageProvider).code,
    );
  }
}
