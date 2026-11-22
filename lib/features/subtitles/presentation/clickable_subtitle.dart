import 'package:flutter/material.dart';
import 'package:learner_video_player/features/subtitles/presentation/clickable_words.dart';

const _subtitleStyle = TextStyle(
  fontSize: 26,
  height: 1.35,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
);

/// Renders subtitle [text] where every word is tappable.
/// The word equal to [highlightedWord] (ignoring case) stays highlighted.
class ClickableSubtitle extends StatelessWidget {
  const ClickableSubtitle({
    super.key,
    required this.text,
    required this.onWordTap,
    this.highlightedWord,
  });

  final String text;
  final ValueChanged<String> onWordTap;
  final String? highlightedWord;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClickableWords(
              text: line,
              style: _subtitleStyle,
              highlightedWord: highlightedWord,
              onWordTap: onWordTap,
            ),
          ),
      ],
    );
  }
}
