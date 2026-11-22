import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/core/choice.dart';
import 'package:learner_video_player/features/player/domain/player_gateway.dart';

/// Wired in `main.dart`.
final playerGatewayProvider = Provider<PlayerGateway>(
  (ref) => throw UnimplementedError('Override playerGatewayProvider'),
);

PlayerGateway _gateway(Ref ref) => ref.watch(playerGatewayProvider);

final playingProvider = StreamProvider<bool>((ref) => _gateway(ref).playing);
final positionProvider = StreamProvider<Duration>(
  (ref) => _gateway(ref).position,
);
final durationProvider = StreamProvider<Duration>(
  (ref) => _gateway(ref).duration,
);
final audioTracksProvider = StreamProvider<List<Choice>>(
  (ref) => _gateway(ref).audioTracks,
);
final subtitleTracksProvider = StreamProvider<List<Choice>>(
  (ref) => _gateway(ref).subtitleTracks,
);
final selectedAudioIdProvider = StreamProvider<String?>(
  (ref) => _gateway(ref).selectedAudioId,
);
final selectedSubtitleIdProvider = StreamProvider<String?>(
  (ref) => _gateway(ref).selectedSubtitleId,
);
final subtitleTextProvider = StreamProvider<String>(
  (ref) => _gateway(ref).subtitleText,
);
