import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/app.dart';
import 'package:learner_video_player/features/player/data/media_kit_player_gateway.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/settings/data/prefs_settings_repository.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/translation/data/webview_translation_launcher.dart';
import 'package:learner_video_player/features/translation/presentation/translation_providers.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        playerGatewayProvider.overrideWith((ref) {
          final gateway = MediaKitPlayerGateway();
          ref.onDispose(gateway.dispose);
          return gateway;
        }),
        translationLauncherProvider.overrideWithValue(
          WebviewTranslationLauncher(),
        ),
        settingsRepositoryProvider.overrideWithValue(
          PrefsSettingsRepository(prefs),
        ),
      ],
      child: const LearnerVideoPlayerApp(),
    ),
  );
}
