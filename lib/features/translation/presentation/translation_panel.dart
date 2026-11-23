import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/sentences/presentation/save_sentence_button.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/presentation/clickable_words.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';

/// Side panel with the current sentence and its translation page, docked to
/// the right of the player.
class TranslationPanel extends ConsumerWidget {
  const TranslationPanel({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.watch(translationLauncherProvider);

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          _SentenceHeader(translated: uri.queryParameters['text'] ?? ''),
          Expanded(
            child: ValueListenableBuilder<TranslationLoadState>(
              valueListenable: launcher.loadState,
              builder: (context, state, _) {
                final failed = state == TranslationLoadState.failed;
                return Column(
                  children: [
                    SizedBox(
                      height: 2,
                      child: state == TranslationLoadState.loading
                          ? const LinearProgressIndicator(minHeight: 2)
                          : null,
                    ),
                    Expanded(
                      child: failed
                          ? _LoadError(onRetry: launcher.reload)
                          : launcher.buildView(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _sentenceStyle = TextStyle(
  fontSize: 18,
  height: 1.4,
  fontWeight: FontWeight.w500,
  color: Colors.white,
);

/// The full subtitle sentence with clickable words, plus "Translate sentence"
/// and "Play again". Falls back to just the looked-up text when the sentence
/// is unknown.
class _SentenceHeader extends ConsumerWidget {
  const _SentenceHeader({required this.translated});

  final String translated;

  Future<void> _translate(WidgetRef ref, String text) async {
    await ref.read(playerGatewayProvider).pause();
    await ref.read(translateTextProvider)(
      text,
      targetLanguageCode: ref.read(nativeLanguageProvider).code,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.watch(translationLauncherProvider);
    final language = ref.watch(nativeLanguageProvider);
    final cue = ref.watch(selectedCueProvider);
    final sentence = cue?.text ?? translated;
    final wholeSentence = translated == sentence;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'English → ${language.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accentSoft,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close (Esc)',
                icon: const Icon(Icons.close_rounded),
                onPressed: launcher.close,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: ClickableWords(
                  text: sentence,
                  style: _sentenceStyle,
                  alignment: WrapAlignment.start,
                  highlightAll: wholeSentence && cue != null,
                  highlightedWord: translated,
                  onWordTap: (word) => _translate(ref, word),
                ),
              ),
            ),
          ),
          if (cue != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _translate(ref, cue.text),
                  icon: const Icon(Icons.translate_rounded, size: 18),
                  label: const Text('Translate sentence'),
                ),
                OutlinedButton.icon(
                  onPressed: cue.canReplay
                      ? () => ref
                            .read(playerGatewayProvider)
                            .playRange(cue.replayFrom, cue.end!)
                      : null,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Play again'),
                ),
                SaveSentenceButton(cue: cue),
              ],
            ),
            SaveSentenceStatus(cue: cue),
          ],
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.white54),
            const SizedBox(height: 12),
            const Text('Could not load the translation'),
            const SizedBox(height: 4),
            const Text(
              'Check your internet connection',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
