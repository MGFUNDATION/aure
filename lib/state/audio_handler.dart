import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Conecta el reproductor con la notificación y la pantalla de bloqueo,
/// para que la música siga sonando en segundo plano.
class AureAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AureAudioHandler() {
    player.playbackEventStream.listen((_) => _broadcast());
    player.currentIndexStream.listen((i) {
      final q = queue.value;
      if (i != null && i < q.length) mediaItem.add(q[i]);
    });
  }

  final AudioPlayer player = AudioPlayer();

  Future<void> setTracks(List<MediaItem> items, int start) async {
    queue.add(items);
    await player.setAudioSources(
      items.map((m) => AudioSource.uri(Uri.parse(m.id))).toList(),
      initialIndex: start,
    );
    mediaItem.add(items[start]);
  }

  void _broadcast() {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[player.processingState]!,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => player.play();
  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> stop() => player.stop();
  @override
  Future<void> seek(Duration position) => player.seek(position);
  @override
  Future<void> skipToNext() => player.seekToNext();
  @override
  Future<void> skipToPrevious() async {
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      player.seek(Duration.zero, index: index);
}
