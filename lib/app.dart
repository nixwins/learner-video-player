import 'package:flutter/material.dart';
import 'package:learner_video_player/features/player/presentation/player_page.dart';

class LearnerVideoPlayerApp extends StatelessWidget {
  const LearnerVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learner Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const PlayerPage(),
    );
  }
}
