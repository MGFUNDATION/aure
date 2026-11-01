import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/environment.dart';
import '../models/track.dart';
import '../services/ads_service.dart';
import '../services/download_service.dart';
import '../services/free_music_service.dart';
import '../services/recognition_service.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../widgets/common.dart';

// ---------------- Mensajes del chat ----------------

sealed class ChatItem {
  const ChatItem();
}

class TextItem extends ChatItem {
  const TextItem(this.text, {this.fromUser = false});
  final String text;
  final bool fromUser;
}

class MatchItem extends ChatItem {
  const MatchItem(this.matches);
  final List<SongMatch> matches;
}

class FreeTracksItem extends ChatItem {
  const FreeTracksItem(this.tracks);
  final List<FreeTrack> tracks;
}

class LocalTracksItem extends ChatItem {
  const LocalTracksItem(this.tracks);
  final List<Track> tracks;
}

class EnvSuggestionItem extends ChatItem {
  const EnvSuggestionItem(this.env);
  final AureEnvironment env;
}

/// Aure IA: tararea, pega un enlace o pide lo que quieras escuchar.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.startHumming = false,
    this.initialMessage,
    this.asTab = false,
  });

  /// Cuando es la pestaña "Buscar" de la barra inferior.
  final bool asTab;
  final bool startHumming;
  final String? initialMessage;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _items = <ChatItem>[];
  final _hum = HumRecognitionService();
  final _links = LinkRecognitionService();
  final _free = FreeMusicService();

  bool _thinking = false;
  bool _listening = false;
  int _listenSecs = 0;
  Timer? _listenTimer;

  @override
  void initState() {
    super.initState();
    final name = context.read<SettingsStore>().userName;
    _items.add(
      TextItem(
        'Hola $name ✨ Soy Aure IA. Puedo:\n'
        '• 🎤 Reconocer una canción si la tarareas o cantas\n'
        '• 🔗 Decirte qué canción es un enlace y dónde escucharla\n'
        '• ⬇️ Descargar gratis música con licencia libre (eliges la calidad)\n'
        '• 🌿 Recomendarte un entorno según cómo te sientas',
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startHumming) _toggleListening();
      if (widget.initialMessage != null) _send(widget.initialMessage!);
    });
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    if (_listening) _hum.cancel();
    super.dispose();
  }

  void _add(ChatItem i) {
    setState(() => _items.add(i));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _online => context.read<SettingsStore>().onlineFeatures;

  // ---------------- Lógica principal ----------------

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    _input.clear();
    _add(TextItem(text, fromUser: true));
    setState(() => _thinking = true);
    try {
      final url = LinkRecognitionService.urlRegex.firstMatch(text)?.group(0);
      if (url != null) {
        await _handleLink(url);
      } else if (_handleMood(text.toLowerCase())) {
        // Respondido con una sugerencia de entorno.
      } else {
        await _handleSearch(
          text.replaceFirst(
            RegExp(
              r'^(buscar|busca|descargar|descarga|pon|reproduce)\s+',
              caseSensitive: false,
            ),
            '',
          ),
        );
      }
    } catch (e) {
      _add(TextItem('Uy, algo falló: $e'));
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  Future<void> _handleLink(String url) async {
    if (!_online) {
      _add(const TextItem('Las funciones en línea están apagadas en Ajustes.'));
      return;
    }
    // 1) ¿Es de un catálogo con licencia libre? Entonces se puede descargar.
    final free = await _free.fromLink(url);
    if (free != null) {
      _add(
        TextItem(
          '¡Esta canción tiene licencia ${free.license}! Puedes descargarla gratis 🎉',
        ),
      );
      _add(FreeTracksItem([free]));
      return;
    }
    // 2) Si no, la reconocemos y mostramos dónde escucharla legalmente.
    final match = await _links.recognize(url);
    if (match == null) {
      _add(const TextItem('No pude reconocer ese enlace. ¿Es de una canción?'));
      return;
    }
    _add(TextItem('Es "${match.title}" de ${match.artist}.'));
    _add(MatchItem([match]));
    _suggestLocalAndFree('${match.title} ${match.artist}', match.title);
  }

  Future<void> _suggestLocalAndFree(String query, String title) async {
    final lib = context.read<LibraryStore>();
    final local = lib.search(title);
    if (local.isNotEmpty) {
      _add(const TextItem('¡Ya la tienes en tu teléfono! 🎧'));
      _add(LocalTracksItem(local.take(3).toList()));
    } else {
      _add(
        const TextItem(
          'Tiene derechos de autor, así que no puedo descargarla, pero puedes '
          'escucharla en los servicios de arriba. Si la compras o la tienes en tu '
          'teléfono, Aure la reproduce sin conexión.',
        ),
      );
    }
  }

  Future<void> _handleSearch(String q) async {
    final lib = context.read<LibraryStore>();
    final local = lib.search(q);
    if (local.isNotEmpty) {
      _add(TextItem('Encontré ${local.length} en tu teléfono:'));
      _add(LocalTracksItem(local.take(5).toList()));
    }
    if (!_online) {
      if (local.isEmpty) _add(TextItem('No encontré "$q" en tu teléfono.'));
      return;
    }
    final free = await _free.search(q);
    if (free.isEmpty) {
      if (local.isEmpty) {
        _add(
          TextItem(
            'No encontré "$q" en tu teléfono ni en música libre. '
            'Prueba tarareándola 🎤 o pegando un enlace.',
          ),
        );
      }
      return;
    }
    _add(const TextItem('Música libre que puedes descargar gratis:'));
    _add(FreeTracksItem(free.take(6).toList()));
  }

  bool _handleMood(String t) {
    const map = {
      'bosque': ['concentr', 'estudi', 'enfoc', 'trabaj', 'focus'],
      'playa': ['estres', 'estrés', 'ansie', 'nervios', 'relaj'],
      'espacio': ['dormir', 'sueño', 'insomn', 'descans'],
      'cabana': ['triste', 'cansad', 'frío', 'frio', 'acogedor'],
      'ciudad': ['energ', 'fiesta', 'feliz', 'motiv', 'gym', 'entren'],
    };
    for (final e in map.entries) {
      if (e.value.any(t.contains)) {
        final env = AureEnvironment.byId(e.key);
        _add(
          TextItem('Te recomiendo ${env.name}: ${env.subtitle.toLowerCase()}.'),
        );
        _add(EnvSuggestionItem(env));
        return true;
      }
    }
    return false;
  }

  // ---------------- Tararear ----------------

  Future<void> _toggleListening() async {
    if (_listening) {
      _listenTimer?.cancel();
      setState(() {
        _listening = false;
        _thinking = true;
      });
      try {
        final matches = await _hum.stopAndRecognize();
        if (matches.isEmpty) {
          _add(
            const TextItem(
              'No la reconocí 😅 Intenta de nuevo, unos 10 segundos y más cerca del micrófono.',
            ),
          );
        } else {
          _add(
            TextItem(
              'Creo que es "${matches.first.title}" de ${matches.first.artist}.',
            ),
          );
          _add(MatchItem(matches.take(3).toList()));
          await _suggestLocalAndFree(
            '${matches.first.title} ${matches.first.artist}',
            matches.first.title,
          );
        }
      } catch (e) {
        _add(TextItem('$e'));
      } finally {
        if (mounted) setState(() => _thinking = false);
      }
      return;
    }
    if (!_online) {
      _add(
        const TextItem(
          'Para reconocer canciones necesito internet. Actívalo en Ajustes.',
        ),
      );
      return;
    }
    try {
      await _hum.start();
      setState(() {
        _listening = true;
        _listenSecs = 0;
      });
      _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _listenSecs++);
        if (_listenSecs >= 12) _toggleListening(); // corta solo a los 12 s
      });
    } catch (e) {
      _add(TextItem('$e'));
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: widget.asTab
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buscar'),
                  Text(
                    'Aure IA · tararea, pega un enlace o escribe',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                  ),
                ],
              )
            : const Row(
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Text('Aure IA'),
                ],
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _items.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _buildItem(_items[i]);
              },
            ),
          ),
          if (_listening)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 40, color: scheme.primary),
                  Text('Te escucho… tararea o canta ($_listenSecs s)'),
                  const Text(
                    'Toca el micrófono para terminar',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _listening
                          ? Colors.redAccent
                          : scheme.primary,
                    ),
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    onPressed: _thinking ? null : _toggleListening,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: _send,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Pega un enlace o escribe…',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(_input.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ChatItem item) {
    final scheme = Theme.of(context).colorScheme;
    switch (item) {
      case TextItem(:final text, :final fromUser):
        return Align(
          alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            decoration: BoxDecoration(
              color: fromUser ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              text,
              style: TextStyle(color: fromUser ? Colors.white : null),
            ),
          ),
        );
      case MatchItem(:final matches):
        return Column(
          children: [for (final m in matches) _MatchCard(match: m)],
        );
      case FreeTracksItem(:final tracks):
        return Column(
          children: [for (final t in tracks) _FreeTrackCard(track: t)],
        );
      case LocalTracksItem(:final tracks):
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < tracks.length; i++)
                TrackTile(
                  track: tracks[i],
                  onTap: () =>
                      context.read<PlayerStore>().playTracks(tracks, start: i),
                ),
            ],
          ),
        );
      case EnvSuggestionItem(:final env):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              EnvironmentCard(env: env, onTap: () {}),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  context.read<SettingsStore>().selectEnvironment(env);
                  context.read<PlayerStore>()
                    ..activeEnvId = env.id
                    ..applyMix(env.defaultMix);
                  _add(TextItem('Listo, ${env.name} activado 🌿'));
                },
                child: const Text('Activar'),
              ),
            ],
          ),
        );
    }
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final SongMatch match;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: match.artworkUrl != null
                      ? Image.network(
                          match.artworkUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Artwork(track: null, size: 56),
                        )
                      : const Artwork(track: null, size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(match.artist),
                      if (match.score != null)
                        Text(
                          'Coincidencia ${match.score!.round()}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (match.links.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Escúchala en:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final l in match.links.entries)
                    ActionChip(
                      label: Text(l.key),
                      onPressed: () => launchUrl(
                        Uri.parse(l.value),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de descarga: elige calidad → anuncio corto → descarga a tu biblioteca.
class _FreeTrackCard extends StatefulWidget {
  const _FreeTrackCard({required this.track});
  final FreeTrack track;

  @override
  State<_FreeTrackCard> createState() => _FreeTrackCardState();
}

class _FreeTrackCardState extends State<_FreeTrackCard> {
  late DownloadQuality _q = context.read<SettingsStore>().downloadQuality;
  double? _progress;
  Track? _done;
  String? _error;

  Future<void> _download() async {
    final lib = context.read<LibraryStore>();
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      if (context.read<SettingsStore>().wifiOnlyDownloads) {
        final net = await Connectivity().checkConnectivity();
        if (!net.contains(ConnectivityResult.wifi) &&
            !net.contains(ConnectivityResult.ethernet)) {
          setState(() {
            _progress = null;
            _error =
                'Estás con datos móviles. Conéctate a Wi-Fi o cambia "Descargar contenidos" en Ajustes.';
          });
          return;
        }
      }
      if (!mounted) return;
      final rewarded = await AdsService().showRewarded();
      if (!rewarded) {
        setState(() {
          _progress = null;
          _error =
              'Mira el anuncio completo para desbloquear la descarga gratis 💜';
        });
        return;
      }
      final d = await FreeMusicService().resolve(widget.track, _q);
      if (d == null) {
        setState(() {
          _progress = null;
          _error = 'Esta calidad no está disponible, prueba otra.';
        });
        return;
      }
      final file = await DownloadService().download(
        widget.track,
        d,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      final t = lib.addDownload(
        file,
        title: widget.track.title,
        artist: widget.track.artist,
        license: widget.track.license,
        durationMs: widget.track.duration?.inMilliseconds ?? 0,
      );
      setState(() {
        _progress = null;
        _done = t;
      });
    } catch (e) {
      setState(() {
        _progress = null;
        _error = 'No se pudo descargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: t.artworkUrl != null
                      ? Image.network(
                          t.artworkUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Artwork(track: null, size: 56),
                        )
                      : const Artwork(track: null, size: 56),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        t.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${t.source} · ${t.license}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_done != null)
              FilledButton.icon(
                onPressed: () =>
                    context.read<PlayerStore>().playTracks([_done!]),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Descargada · Reproducir'),
              )
            else if (_progress != null)
              LinearProgressIndicator(value: _progress == 0 ? null : _progress)
            else ...[
              SegmentedButton<DownloadQuality>(
                showSelectedIcon: false,
                segments: [
                  for (final q in DownloadQuality.values)
                    ButtonSegment(value: q, label: Text(q.label)),
                ],
                selected: {_q},
                onSelectionChanged: (v) => setState(() => _q = v.first),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download),
                label: const Text('Ver anuncio corto y descargar'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
