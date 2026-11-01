import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'free_music_service.dart';

/// Descarga un archivo de audio con licencia libre a la carpeta de Aure.
class DownloadService {
  Future<File> download(
    FreeTrack t,
    FreeDownload d, {
    void Function(double progress)? onProgress,
  }) async {
    final base =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/Aure');
    await dir.create(recursive: true);
    final safe = '${t.artist} - ${t.title}'.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
    final file = File('${dir.path}/$safe.${d.extension}');

    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(d.url)));
      if (res.statusCode >= 400) {
        throw HttpException('Error ${res.statusCode} al descargar');
      }
      final total = res.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }
}
