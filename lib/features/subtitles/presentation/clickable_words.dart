import 'package:flutter/material.dart';
import 'package:learner_video_player/core/theme.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_tokenizer.dart';

/// One line of text where every word is tappable. A word equal to
/// [highlightedWord] (ignoring case) stays highlighted, and so does every word
/// when [highlightAll] is set.
class ClickableWords extends StatelessWidget {
  const ClickableWords({
    super.key,
    required this.text,
    required this.style,
    required this.onWordTap,
    this.highlightedWord,
    this.highlightAll = false,
    this.alignment = WrapAlignment.center,
  });

  final String text;
  final TextStyle style;
  final ValueChanged<String> onWordTap;
  final String? highlightedWord;
  final bool highlightAll;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final highlighted = highlightedWord?.toLowerCase();
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final token in tokenizeSubtitle(text))
          token.isWord
              ? _Word(
                  token.text,
                  style: style,
                  active:
                      highlightAll || token.text.toLowerCase() == highlighted,
                  onTap: () => onWordTap(token.text),
                )
              : Text(token.text, style: style),
      ],
    );
  }
}

class _Word extends StatefulWidget {
  const _Word(
    this.word, {
    required this.style,
    required this.active,
    required this.onTap,
  });

  final String word;
  final TextStyle style;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_Word> createState() => _WordState();
}

class _WordState extends State<_Word> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.word,
          style: widget.style.copyWith(
            color: highlighted ? AppColors.accentSoft : widget.style.color,
            decoration: highlighted ? TextDecoration.underline : null,
            decorationColor: AppColors.accentSoft,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}
