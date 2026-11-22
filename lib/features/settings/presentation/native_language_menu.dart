import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/core/languages.dart';
import 'package:learner_video_player/core/widgets/option_menu_button.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';

final _languageChoices = [
  for (final language in supportedLanguages)
    Choice(id: language.code, label: language.name),
];

class NativeLanguageMenu extends ConsumerWidget {
  const NativeLanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OptionMenuButton(
      icon: Icons.translate_rounded,
      tooltip: 'Translate into',
      options: _languageChoices,
      selectedId: ref.watch(nativeLanguageProvider).code,
      onSelected: ref.read(nativeLanguageProvider.notifier).select,
    );
  }
}
