import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learner_video_player/features/player/presentation/player_providers.dart';
import 'package:learner_video_player/features/sentences/domain/clip_cutter.dart';
import 'package:learner_video_player/features/sentences/domain/save_sentence.dart';
import 'package:learner_video_player/features/sentences/domain/sentence_repository.dart';
import 'package:learner_video_player/features/settings/presentation/settings_providers.dart';
import 'package:learner_video_player/features/subtitles/domain/subtitle_cue.dart';

/// Wired in `main.dart`.
final sentenceRepositoryProvider = Provider<SentenceRepository>(
  (ref) => throw UnimplementedError('Override sentenceRepositoryProvider'),
);

/// Wired in `main.dart`.
final clipCutterProvider = Provider<ClipCutter>(
  (ref) => throw UnimplementedError('Override clipCutterProvider'),
);

final saveSentenceProvider = Provider<SaveSentence>(
  (ref) => SaveSentence(
    repository: ref.watch(sentenceRepositoryProvider),
    cutter: ref.watch(clipCutterProvider),
  ),
);

enum SaveStatus { idle, saving, saved, failed }

class SaveState {
  const SaveState(this.status, {this.message});

  static const idle = SaveState(SaveStatus.idle);

  final SaveStatus status;
  final String? message;
}

/// Identifies a sentence so that each one remembers its own save state.
String cueKey(SubtitleCue cue) => '${cue.start?.inMilliseconds}|${cue.text}';

/// Save state per sentence. A saved sentence cannot be saved twice from here,
/// because the server would store a duplicate.
class SentenceSaveNotifier extends Notifier<Map<String, SaveState>> {
  @override
  Map<String, SaveState> build() => const {};

  SaveState stateOf(SubtitleCue cue) => state[cueKey(cue)] ?? SaveState.idle;

  Future<void> save(SubtitleCue cue) async {
    final key = cueKey(cue);
    final current = stateOf(cue).status;
    if (current == SaveStatus.saving || current == SaveStatus.saved) return;

    final credentials = ref.read(freqAppSettingsProvider).credentials;
    if (credentials == null) {
      _set(
        key,
        const SaveState(
          SaveStatus.failed,
          message: 'Add the server address and API key in Settings first.',
        ),
      );
      return;
    }

    _set(key, const SaveState(SaveStatus.saving));
    try {
      final saved = await ref.read(saveSentenceProvider)(
        cue: cue,
        source: ref.read(playerGatewayProvider).currentSource(),
        credentials: credentials,
      );
      _set(
        key,
        SaveState(
          SaveStatus.saved,
          message: saved.withVideo
              ? 'Saved with its video fragment.'
              : 'Saved without a video: the exact timing of this sentence is '
                    'unknown.',
        ),
      );
    } on SentenceSaveException catch (e) {
      _set(key, SaveState(SaveStatus.failed, message: e.message));
    } catch (e) {
      _set(key, SaveState(SaveStatus.failed, message: 'Could not save: $e'));
    }
  }

  void _set(String key, SaveState value) => state = {...state, key: value};
}

final sentenceSaveProvider =
    NotifierProvider<SentenceSaveNotifier, Map<String, SaveState>>(
      SentenceSaveNotifier.new,
    );
