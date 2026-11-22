import 'package:flutter/material.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_tokenizer.dart';

const _subtitleStyle = TextStyle(
  fontSize: 26,
  height: 1.3,
  fontWeight: FontWeight.w500,
  color: Colors.white,
);

/// Renders subtitle [text] where every word is tappable.
class ClickableSubtitle extends StatelessWidget {
  const ClickableSubtitle({
    super.key,
    required this.text,
    required this.onWordTap,
  });

  final String text;
  final ValueChanged<String> onWordTap;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final token in tokenizeSubtitle(line))
                  token.isWord
                      ? _Word(token.text, onTap: () => onWordTap(token.text))
                      : Text(token.text, style: _subtitleStyle),
              ],
            ),
          ),
      ],
    );
  }
}

class _Word extends StatefulWidget {
  const _Word(this.word, {required this.onTap});

  final String word;
  final VoidCallback onTap;

  @override
  State<_Word> createState() => _WordState();
}

class _WordState extends State<_Word> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.word,
          style: _subtitleStyle.copyWith(
            color: _hovered ? Colors.amberAccent : Colors.white,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: Colors.amberAccent,
          ),
        ),
      ),
    );
  }
}
