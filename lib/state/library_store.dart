import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Lee la música guardada en el teléfono (funciona 100% sin conexión)
/// y administra favoritos y playlists del usuario.
class LibraryStore extends ChangeNotifier {
  LibraryStore(this._prefs) {
    _loadUserData();
  }

  final SharedPreferences _prefs;
  final OnAudioQuery _query = OnAudioQuery();

  List<Track> _deviceTracks = [];
  List<Track> downloads = [];
  List<Track> get tracks => [...downloads, ..._deviceTracks];
  bool loading = false;
  bool permissionDenied = false;
  Set<int> favorites = {};
  List<Playlist> playlists = [];

  OnAudioQuery get query => _query;

  void _loadUserData() {
    favorites = (_prefs.getStringList('favorites') ?? [])
        .map(int.parse)
        .toSet();
    final dl = _prefs.getString('downloads');
    if (dl != null) {
      downloads = (jsonDecode(dl) as List)
          .cast<Map<String, dynamic>>()
          .where((m) => File(m['path'] as String).existsSync())
          .map(
            (m) => Track(
              id: m['id'] as int,
              title: m['title'] as String,
              artist: m['artist'] as String,
              album: m['album'] as String? ?? 'Descargas libres',
              uri: Uri.file(m['path'] as String).toString(),
              path: m['path'] as String,
              durationMs: m['durationMs'] as int? ?? 0,
            ),
          )
          .toList();
    }
    final raw = _prefs.getString('playlists');
    if (raw != null) {
      playlists = (jsonDecode(raw) as List)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  /// Registra una canción descargada (con licencia libre) en la biblioteca.
  Track addDownload(
    File file, {
    required String title,
    required String artist,
    String? license,
    int durationMs = 0,
  }) {
    final t = Track(
      id: -DateTime.now().millisecondsSinceEpoch, // ids negativos = descargas
      title: title,
      artist: artist,
      album: license == null
          ? 'Descargas libres'
          : 'Descargas libres · $license',
      uri: Uri.file(file.path).toString(),
      path: file.path,
      durationMs: durationMs,
    );
    downloads.insert(0, t);
    notifyListeners();
    _saveUserData();
    return t;
  }

  Future<void> _saveUserData() async {
    await _prefs.setString(
      'downloads',
      jsonEncode(
        downloads
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'artist': t.artist,
                'album': t.album,
                'path': t.path,
                'durationMs': t.durationMs,
              },
            )
            .toList(),
      ),
    );
    await _prefs.setStringList(
      'favorites',
      favorites.map((e) => e.toString()).toList(),
    );
    await _prefs.setString(
      'playlists',
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<bool> _ensurePermission() async {
    if (kIsWeb) return false;
    // Android 13+ usa READ_MEDIA_AUDIO, versiones previas usan almacenamiento.
    var status = await Permission.audio.request();
    if (!status.isGranted) status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> scan() async {
    loading = true;
    notifyListeners();
    try {
      if (!await _ensurePermission()) {
        permissionDenied = true;
        return;
      }
      permissionDenied = false;
      final songs = await _query.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      _deviceTracks = songs
          .where((s) => (s.isMusic ?? true) && (s.duration ?? 0) > 30000)
          .map(
            (s) => Track(
              id: s.id,
              title: s.title,
              artist: s.artist ?? '',
              album: s.album ?? '',
              uri: s.uri ?? '',
              path: s.data,
              durationMs: s.duration ?? 0,
              albumId: s.albumId,
              genre: s.genre,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error leyendo biblioteca: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Track? byId(int id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Track> search(String q) {
    final s = q.toLowerCase().trim();
    if (s.isEmpty) return tracks;
    return tracks
        .where(
          (t) =>
              t.title.toLowerCase().contains(s) ||
              t.artist.toLowerCase().contains(s) ||
              t.album.toLowerCase().contains(s),
        )
        .toList();
  }

  Map<String, List<Track>> get byArtist {
    final m = <String, List<Track>>{};
    for (final t in tracks) {
      m.putIfAbsent(t.displayArtist, () => []).add(t);
    }
    return m;
  }

  Map<String, List<Track>> get byAlbum {
    final m = <String, List<Track>>{};
    for (final t in tracks) {
      m.putIfAbsent(t.album.isEmpty ? 'Sin álbum' : t.album, () => []).add(t);
    }
    return m;
  }

  List<Track> get favoriteTracks =>
      tracks.where((t) => favorites.contains(t.id)).toList();

  bool isFavorite(int id) => favorites.contains(id);

  void toggleFavorite(int id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    notifyListeners();
    _saveUserData();
  }

  Playlist createPlaylist(String name) {
    final p = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    playlists.add(p);
    notifyListeners();
    _saveUserData();
    return p;
  }

  void addToPlaylist(Playlist p, int trackId) {
    if (!p.trackIds.contains(trackId)) p.trackIds.add(trackId);
    notifyListeners();
    _saveUserData();
  }

  void removeFromPlaylist(Playlist p, int trackId) {
    p.trackIds.remove(trackId);
    notifyListeners();
    _saveUserData();
  }

  void deletePlaylist(Playlist p) {
    playlists.remove(p);
    notifyListeners();
    _saveUserData();
  }

  void renamePlaylist(Playlist p, String name) {
    p.name = name;
    notifyListeners();
    _saveUserData();
  }

  List<Track> tracksOf(Playlist p) =>
      p.trackIds.map(byId).whereType<Track>().toList();
}
