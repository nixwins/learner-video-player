import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/features/translation/domain/translate_word.dart';
import 'package:learner_video_player/features/translation/domain/translation_launcher.dart';

/// Wired in `main.dart`.
final translationLauncherProvider = Provider<TranslationLauncher>(
  (ref) => throw UnimplementedError('Override translationLauncherProvider'),
);

final translateWordProvider = Provider<TranslateWord>(
  (ref) => TranslateWord(ref.watch(translationLauncherProvider)),
);
