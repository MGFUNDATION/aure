/// Una canción guardada en el dispositivo.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.durationMs,
    this.path,
    this.albumId,
    this.genre,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final String? path;
  final int durationMs;
  final int? albumId;
  final String? genre;

  Duration get duration => Duration(milliseconds: durationMs);

  String get displayArtist => (artist.isEmpty || artist == '<unknown>')
      ? 'Artista desconocido'
      : artist;
}

class Playlist {
  Playlist({required this.id, required this.name, List<int>? trackIds})
    : trackIds = trackIds ?? [];

  final String id;
  String name;
  final List<int> trackIds;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'tracks': trackIds};

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
    id: j['id'] as String,
    name: j['name'] as String,
    trackIds: (j['tracks'] as List).cast<int>(),
  );
}
