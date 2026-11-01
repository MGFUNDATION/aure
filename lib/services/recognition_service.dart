import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'config.dart';

/// Resultado de reconocer una canción (por tarareo o por enlace).
class SongMatch {
  SongMatch({
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    this.score,
    Map<String, String>? links,
  }) : links = links ?? {};

  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final double? score;

  /// Plataforma → URL (Spotify, YouTube Music, Deezer, Apple Music...).
  final Map<String, String> links;
}

class RecognitionException implements Exception {
  RecognitionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// "Tararea o canta y Aure encuentra la canción".
/// Graba unos segundos del micrófono y los envía a ACRCloud, que tiene
/// reconocimiento de tarareo (humming) además de grabaciones originales.
class HumRecognitionService {
  final AudioRecorder _rec = AudioRecorder();
  String? _path;

  Future<bool> hasPermission() => _rec.hasPermission();

  Future<void> start() async {
    if (!await _rec.hasPermission()) {
      throw RecognitionException(
        'Necesito permiso del micrófono para escucharte.',
      );
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/aure_hum.m4a';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _path!,
    );
  }

  Future<void> cancel() async {
    await _rec.cancel();
  }

  Future<List<SongMatch>> stopAndRecognize() async {
    final path = await _rec.stop() ?? _path;
    if (path == null) throw RecognitionException('No se grabó audio.');
    if (!AureConfig.hasAcr) {
      throw RecognitionException(
        'El reconocimiento por tarareo aún no está configurado (faltan las claves de ACRCloud).',
      );
    }
    final bytes = await File(path).readAsBytes();
    return _identify(bytes);
  }

  Future<List<SongMatch>> _identify(List<int> sample) async {
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final toSign = [
      'POST',
      '/v1/identify',
      AureConfig.acrKey,
      'audio',
      '1',
      ts,
    ].join('\n');
    final signature = base64.encode(
      Hmac(
        sha1,
        utf8.encode(AureConfig.acrSecret),
      ).convert(utf8.encode(toSign)).bytes,
    );

    final req =
        http.MultipartRequest(
            'POST',
            Uri.https(AureConfig.acrHost, '/v1/identify'),
          )
          ..fields.addAll({
            'access_key': AureConfig.acrKey,
            'sample_bytes': '${sample.length}',
            'timestamp': ts,
            'signature': signature,
            'data_type': 'audio',
            'signature_version': '1',
          })
          ..files.add(
            http.MultipartFile.fromBytes('sample', sample, filename: 'hum.m4a'),
          );

    final res = await http.Response.fromStream(
      await req.send().timeout(const Duration(seconds: 20)),
    );
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final code = (j['status']?['code'] as num?)?.toInt();
    if (code == 1001) return [];
    if (code != 0) {
      throw RecognitionException(
        'No pude reconocerla ahora (${j['status']?['msg']}).',
      );
    }
    final meta = j['metadata'] as Map<String, dynamic>? ?? {};
    final raw = [
      ...(meta['music'] as List? ?? []),
      ...(meta['humming'] as List? ?? []),
    ].cast<Map<String, dynamic>>();

    final out = <SongMatch>[];
    for (final m in raw) {
      final ext = m['external_metadata'] as Map<String, dynamic>? ?? {};
      final links = <String, String>{};
      final sp = ext['spotify']?['track']?['id'];
      if (sp != null) links['Spotify'] = 'https://open.spotify.com/track/$sp';
      final yt = ext['youtube']?['vid'];
      if (yt != null) {
        links['YouTube'] = 'https://music.youtube.com/watch?v=$yt';
      }
      final dz = ext['deezer']?['track']?['id'];
      if (dz != null) links['Deezer'] = 'https://www.deezer.com/track/$dz';
      out.add(
        SongMatch(
          title: m['title'] as String? ?? 'Desconocida',
          artist:
              ((m['artists'] as List?)?.map((a) => a['name']).join(', ')) ?? '',
          album: m['album']?['name'] as String?,
          score: (m['score'] as num?)?.toDouble(),
          links: links,
        ),
      );
    }
    return out;
  }
}

/// Reconoce una canción a partir de un enlace (Spotify, YouTube, Apple Music,
/// Deezer, Tidal, SoundCloud...) usando la API pública de Odesli / song.link,
/// y devuelve dónde escucharla legalmente.
class LinkRecognitionService {
  static final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

  static const _platformNames = {
    'spotify': 'Spotify',
    'youtubeMusic': 'YouTube Music',
    'youtube': 'YouTube',
    'appleMusic': 'Apple Music',
    'deezer': 'Deezer',
    'tidal': 'Tidal',
    'amazonMusic': 'Amazon Music',
    'soundcloud': 'SoundCloud',
  };

  Future<SongMatch?> recognize(String url) async {
    final uri = Uri.https('api.song.link', '/v1-alpha.1/links', {'url': url});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final entities = j['entitiesByUniqueId'] as Map<String, dynamic>? ?? {};
    final entity =
        entities[j['entityUniqueId']] as Map<String, dynamic>? ??
        (entities.values.isEmpty
            ? null
            : entities.values.first as Map<String, dynamic>);
    if (entity == null) return null;
    final platforms = j['linksByPlatform'] as Map<String, dynamic>? ?? {};
    final links = <String, String>{
      for (final e in _platformNames.entries)
        if (platforms[e.key]?['url'] != null)
          e.value: platforms[e.key]['url'] as String,
    };
    if (j['pageUrl'] != null) links['Todas'] = j['pageUrl'] as String;
    return SongMatch(
      title: entity['title'] as String? ?? 'Desconocida',
      artist: entity['artistName'] as String? ?? '',
      artworkUrl: entity['thumbnailUrl'] as String?,
      links: links,
    );
  }
}
