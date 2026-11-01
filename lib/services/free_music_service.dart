import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/settings_store.dart';
import 'config.dart';

/// Canción de un catálogo que PERMITE la descarga gratuita
/// (Creative Commons / dominio público).
class FreeTrack {
  FreeTrack({
    required this.source,
    required this.id,
    required this.title,
    required this.artist,
    required this.license,
    this.artworkUrl,
    this.duration,
    this.pageUrl,
  });

  final String source; // 'Jamendo' | 'Internet Archive'
  final String id;
  final String title;
  final String artist;
  final String license;
  final String? artworkUrl;
  final Duration? duration;
  final String? pageUrl;
}

class FreeDownload {
  FreeDownload(this.url, this.extension);
  final String url;
  final String extension;
}

/// Busca y descarga música libre de derechos o con licencia que permite
/// descargarla. Nunca descarga de servicios con derechos reservados.
class FreeMusicService {
  // ------------- Búsqueda -------------

  Future<List<FreeTrack>> search(String query) async {
    final results = await Future.wait(
      [
        if (AureConfig.hasJamendo) _jamendo(query),
        _archive(query),
      ].map((f) => f.catchError((_) => <FreeTrack>[])),
    );
    return results.expand((e) => e).toList();
  }

  /// Si el enlace pegado es de un catálogo libre, lo devuelve listo para descargar.
  Future<FreeTrack?> fromLink(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return null;
    if (u.host.contains('jamendo.com') && AureConfig.hasJamendo) {
      final m = RegExp(r'/track/(\d+)').firstMatch(u.path);
      if (m != null) {
        final r = await _jamendoQuery({'id': m.group(1)!});
        return r.isEmpty ? null : r.first;
      }
    }
    if (u.host.contains('archive.org')) {
      final m = RegExp(r'/details/([^/?#]+)').firstMatch(u.path);
      if (m != null) return _archiveItem(m.group(1)!);
    }
    return null;
  }

  Future<List<FreeTrack>> _jamendo(String q) =>
      _jamendoQuery({'search': q, 'limit': '10'});

  Future<List<FreeTrack>> _jamendoQuery(Map<String, String> params) async {
    final uri = Uri.https('api.jamendo.com', '/v3.0/tracks/', {
      'client_id': AureConfig.jamendoClientId,
      'format': 'json',
      'audiodlformat': 'mp32',
      ...params,
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (j['results'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((t) => t['audiodownload_allowed'] == true)
        .map(
          (t) => FreeTrack(
            source: 'Jamendo',
            id: '${t['id']}',
            title: t['name'] as String,
            artist: t['artist_name'] as String,
            license: _ccName(t['license_ccurl'] as String?),
            artworkUrl: t['image'] as String?,
            duration: Duration(seconds: (t['duration'] as num?)?.toInt() ?? 0),
            pageUrl: t['shareurl'] as String?,
          ),
        )
        .toList();
  }

  Future<List<FreeTrack>> _archive(String q) async {
    final uri = Uri.https('archive.org', '/advancedsearch.php', {
      'q':
          '($q) AND mediatype:(audio) AND (licenseurl:*creativecommons* OR licenseurl:*publicdomain*)',
      'fl[]': ['identifier', 'title', 'creator', 'licenseurl'],
      'rows': '10',
      'output': 'json',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    final docs = (jsonDecode(res.body)['response']?['docs'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return docs
        .map(
          (d) => FreeTrack(
            source: 'Internet Archive',
            id: d['identifier'] as String,
            title: _str(d['title']) ?? d['identifier'] as String,
            artist: _str(d['creator']) ?? 'Desconocido',
            license: _ccName(_str(d['licenseurl'])),
            artworkUrl: 'https://archive.org/services/img/${d['identifier']}',
            pageUrl: 'https://archive.org/details/${d['identifier']}',
          ),
        )
        .toList();
  }

  Future<FreeTrack?> _archiveItem(String id) async {
    final res = await http
        .get(Uri.https('archive.org', '/metadata/$id'))
        .timeout(const Duration(seconds: 10));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final meta = j['metadata'] as Map<String, dynamic>? ?? {};
    final lic = _str(meta['licenseurl']) ?? '';
    if (!lic.contains('creativecommons') && !lic.contains('publicdomain')) {
      return null; // No tiene licencia que permita descargar.
    }
    return FreeTrack(
      source: 'Internet Archive',
      id: id,
      title: _str(meta['title']) ?? id,
      artist: _str(meta['creator']) ?? 'Desconocido',
      license: _ccName(lic),
      artworkUrl: 'https://archive.org/services/img/$id',
      pageUrl: 'https://archive.org/details/$id',
    );
  }

  // ------------- Enlace de descarga según calidad -------------

  Future<FreeDownload?> resolve(FreeTrack t, DownloadQuality q) async {
    if (t.source == 'Jamendo') {
      final fmt = switch (q) {
        DownloadQuality.low => 'mp31',
        DownloadQuality.medium => 'mp32',
        DownloadQuality.high => 'flac',
      };
      final uri = Uri.https('api.jamendo.com', '/v3.0/tracks/', {
        'client_id': AureConfig.jamendoClientId,
        'id': t.id,
        'audiodlformat': fmt,
      });
      final j = jsonDecode((await http.get(uri)).body) as Map<String, dynamic>;
      final r = (j['results'] as List?)?.cast<Map<String, dynamic>>();
      final url = r?.isNotEmpty == true
          ? r!.first['audiodownload'] as String?
          : null;
      if (url == null || url.isEmpty) return null;
      return FreeDownload(url, q == DownloadQuality.high ? 'flac' : 'mp3');
    }

    // Internet Archive: elegir el archivo según la calidad.
    final res = await http.get(Uri.https('archive.org', '/metadata/${t.id}'));
    final files = ((jsonDecode(res.body)['files']) as List? ?? [])
        .cast<Map<String, dynamic>>();
    Map<String, dynamic>? pick(List<String> formats) {
      for (final f in formats) {
        for (final file in files) {
          if (file['format'] == f) return file;
        }
      }
      return null;
    }

    final file = switch (q) {
      DownloadQuality.low => pick(['64Kbps MP3', 'VBR MP3', 'Ogg Vorbis']),
      DownloadQuality.medium => pick([
        'VBR MP3',
        '128Kbps MP3',
        'Ogg Vorbis',
        '64Kbps MP3',
      ]),
      DownloadQuality.high => pick(['Flac', '24bit Flac', 'VBR MP3']),
    };
    if (file == null) return null;
    final name = file['name'] as String;
    return FreeDownload(
      'https://archive.org/download/${t.id}/${Uri.encodeComponent(name)}',
      name.split('.').last,
    );
  }

  static String? _str(dynamic v) => v is List ? v.join(', ') : v as String?;

  static String _ccName(String? url) {
    if (url == null || url.isEmpty) return 'Licencia libre';
    if (url.contains('publicdomain')) return 'Dominio público';
    final m = RegExp(r'licenses/([a-z-]+)/').firstMatch(url);
    return m == null ? 'Creative Commons' : 'CC ${m.group(1)!.toUpperCase()}';
  }
}
