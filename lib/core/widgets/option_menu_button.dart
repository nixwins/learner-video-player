import 'package:flutter/material.dart';
import 'package:learner_video_player/core/choice.dart';

/// A toolbar button that opens a menu of [options] with a check mark on the
/// one whose id equals [selectedId]. Used for audio tracks, subtitles and
/// languages.
class OptionMenuButton extends StatelessWidget {
  const OptionMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.options,
    required this.onSelected,
    this.selectedId,
  });

  final IconData icon;
  final String tooltip;
  final List<Choice> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in options)
          CheckedPopupMenuItem<String>(
            value: option.id,
            checked: option.id == selectedId,
            child: Text(option.label),
          ),
      ],
    );
  }
}
