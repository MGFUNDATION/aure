import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/environment.dart';
import '../models/track.dart';
import 'audio_handler.dart';
import 'stats_store.dart';

/// Estado del reproductor: cola, canción actual, sonidos ambientales,
/// temporizador de sueño y registro de estadísticas.
class PlayerStore extends ChangeNotifier {
  PlayerStore(this._handler, this._stats) {
    _player.currentIndexStream.listen((i) {
      if (i != null && i < _queue.length) {
        current = _queue[i];
        _stats.recordPlay(current!);
        notifyListeners();
      }
    });
    _player.playingStream.listen((p) {
      playing = p;
      notifyListeners();
    });
    // Cada 10 segundos de reproducción suma tiempo a las estadísticas.
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (playing && current != null) {
        _stats.addListening(current!, 10, envId: activeEnvId);
      }
    });
  }

  final AureAudioHandler _handler;
  final StatsStore _stats;
  AudioPlayer get _player => _handler.player;

  List<Track> _queue = [];
  Track? current;
  bool playing = false;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  String? activeEnvId;
  Timer? _ticker;

  // ---- Temporizador de sueño ----
  DateTime? sleepAt;
  Timer? _sleepTimer;

  // ---- Sonidos ambientales: un reproductor en bucle por sonido ----
  final Map<AmbientSound, AudioPlayer> _ambient = {};
  final Map<AmbientSound, double> ambientVolumes = {};
  double ambientMaster = 0.7;

  List<Track> get queue => List.unmodifiable(_queue);
  Stream<Duration> get position => _player.positionStream;
  Duration get duration =>
      _player.duration ?? current?.duration ?? Duration.zero;

  Future<void> playTracks(List<Track> tracks, {int start = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List.of(tracks);
    current = _queue[start];
    notifyListeners();
    await _handler.setTracks(
      _queue
          .map(
            (t) => MediaItem(
              id: t.uri,
              title: t.title,
              artist: t.displayArtist,
              album: t.album,
              duration: t.duration,
              extras: {'trackId': t.id},
            ),
          )
          .toList(),
      start,
    );
    await _handler.play();
  }

  Future<void> togglePlay() => playing ? _handler.pause() : _handler.play();
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();
  Future<void> seek(Duration d) => _handler.seek(d);

  Future<void> toggleShuffle() async {
    shuffle = !shuffle;
    await _player.setShuffleModeEnabled(shuffle);
    if (shuffle) await _player.shuffle();
    notifyListeners();
  }

  Future<void> cycleLoop() async {
    loop = switch (loop) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(loop);
    notifyListeners();
  }

  void setSleepTimer(Duration? d) {
    _sleepTimer?.cancel();
    if (d == null) {
      sleepAt = null;
    } else {
      sleepAt = DateTime.now().add(d);
      _sleepTimer = Timer(d, () async {
        await _handler.pause();
        await stopAmbient();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // ---------------- Ambiente ----------------

  Future<void> setAmbient(AmbientSound s, double volume) async {
    ambientVolumes[s] = volume;
    if (volume <= 0.01) {
      await _ambient.remove(s)?.dispose();
    } else {
      var p = _ambient[s];
      if (p == null) {
        p = AudioPlayer();
        _ambient[s] = p;
        await p.setAsset(s.asset);
        await p.setLoopMode(LoopMode.one);
        p.play();
      }
      await p.setVolume(volume * ambientMaster);
    }
    notifyListeners();
  }

  Future<void> setAmbientMaster(double v) async {
    ambientMaster = v;
    for (final e in _ambient.entries) {
      await e.value.setVolume((ambientVolumes[e.key] ?? 0) * v);
    }
    notifyListeners();
  }

  Future<void> applyMix(Map<AmbientSound, double> mix) async {
    for (final s in AmbientSound.values) {
      await setAmbient(s, mix[s] ?? 0);
    }
  }

  Future<void> stopAmbient() async {
    for (final p in _ambient.values) {
      await p.dispose();
    }
    _ambient.clear();
    ambientVolumes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sleepTimer?.cancel();
    stopAmbient();
    super.dispose();
  }
}
