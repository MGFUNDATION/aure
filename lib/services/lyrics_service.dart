import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration? time;
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, {required this.synced, required this.source});
  final List<LyricLine> lines;
  final bool synced;
  final String source;
}

/// Busca letras en este orden:
/// 1. Archivo .lrc o .txt junto a la canción (offline).
/// 2. Caché local de letras ya descargadas (offline).
/// 3. LRCLIB (base de datos abierta de letras, requiere internet).
class LyricsService {
  static final _lrcTime = RegExp(r'\[(\d+):(\d+)(?:[.:](\d+))?\]');

  Future<Lyrics?> find(Track t, {bool allowOnline = true}) async {
    final local = await _fromSidecar(t);
    if (local != null) return local;

    final cacheFile = await _cacheFile(t);
    if (await cacheFile.exists()) {
      return parse(await cacheFile.readAsString(), source: 'Guardada');
    }
    if (!allowOnline) return null;

    try {
      final uri = Uri.https('lrclib.net', '/api/get', {
        'track_name': t.title,
        'artist_name': t.displayArtist,
        if (t.album.isNotEmpty) 'album_name': t.album,
        'duration': '${t.durationMs ~/ 1000}',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'Aure/0.1 (app de música)'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (j['syncedLyrics'] ?? j['plainLyrics']) as String?;
      if (text == null || text.trim().isEmpty) return null;
      await cacheFile.writeAsString(text);
      return parse(text, source: 'LRCLIB');
    } catch (_) {
      return null;
    }
  }

  Future<Lyrics?> _fromSidecar(Track t) async {
    final p = t.path;
    if (p == null) return null;
    final base = p.contains('.') ? p.substring(0, p.lastIndexOf('.')) : p;
    for (final ext in ['.lrc', '.txt']) {
      final f = File('$base$ext');
      if (await f.exists()) {
        return parse(await f.readAsString(), source: 'Archivo');
      }
    }
    return null;
  }

  Future<File> _cacheFile(Track t) async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/lyrics',
    );
    await dir.create(recursive: true);
    final key = '${t.displayArtist}-${t.title}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .toLowerCase();
    return File('${dir.path}/$key.lrc');
  }

  static Lyrics parse(String raw, {required String source}) {
    final lines = <LyricLine>[];
    var synced = false;
    for (final l in const LineSplitter().convert(raw)) {
      final matches = _lrcTime.allMatches(l).toList();
      final text = l.replaceAll(_lrcTime, '').trim();
      if (matches.isEmpty) {
        if (!l.startsWith('[')) lines.add(LyricLine(null, l.trim()));
        continue;
      }
      synced = true;
      for (final m in matches) {
        final frac = m.group(3) ?? '0';
        final ms = int.parse(frac.padRight(3, '0').substring(0, 3));
        lines.add(
          LyricLine(
            Duration(
              minutes: int.parse(m.group(1)!),
              seconds: int.parse(m.group(2)!),
              milliseconds: ms,
            ),
            text,
          ),
        );
      }
    }
    if (synced) {
      lines.removeWhere((l) => l.time == null);
      lines.sort((a, b) => a.time!.compareTo(b.time!));
    }
    return Lyrics(lines, synced: synced, source: source);
  }
}
