import 'package:flutter/material.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../models/track.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import 'scene_view.dart';

String fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

String fmtMinutes(double minutes) {
  final h = minutes ~/ 60;
  final m = (minutes % 60).round();
  if (h == 0) return '$m min';
  return '$h h $m min';
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// Carátula de una canción del dispositivo, con un degradado si no tiene.
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.track,
    this.size = 48,
    this.radius = 10,
  });
  final Track? track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: size * 0.45),
    );
    final t = track;
    if (t == null || t.id < 0) return fallback;
    return SizedBox(
      width: size,
      height: size,
      child: QueryArtworkWidget(
        id: t.id,
        type: ArtworkType.AUDIO,
        artworkWidth: size,
        artworkHeight: size,
        artworkBorder: BorderRadius.circular(radius),
        size: (size * 3).toInt(),
        keepOldArtwork: true,
        nullArtworkWidget: fallback,
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.trailing,
  });
  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerStore>();
    final isCurrent = player.current?.id == track.id;
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Artwork(track: track),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isCurrent ? accent : null,
        ),
      ),
      subtitle: Text(
        '${track.displayArtist} · ${fmtDuration(track.duration)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? TrackMenu(track: track),
    );
  }
}

class TrackMenu extends StatelessWidget {
  const TrackMenu({super.key, required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryStore>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        if (v == 'fav') lib.toggleFavorite(track.id);
        if (v == 'pl') await showAddToPlaylist(context, track);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'fav',
          child: Text(
            lib.isFavorite(track.id)
                ? 'Quitar de favoritos'
                : 'Añadir a favoritos',
          ),
        ),
        const PopupMenuItem(value: 'pl', child: Text('Añadir a playlist')),
      ],
    );
  }
}

Future<void> showAddToPlaylist(BuildContext context, Track track) async {
  final lib = context.read<LibraryStore>();
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nueva playlist'),
            onTap: () async {
              final name = await promptText(ctx, 'Nombre de la playlist');
              if (name != null && name.isNotEmpty) {
                lib.addToPlaylist(lib.createPlaylist(name), track.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          for (final p in lib.playlists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.trackIds.length} canciones'),
              onTap: () {
                lib.addToPlaylist(p, track.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

Future<String?> promptText(
  BuildContext context,
  String title, {
  String initial = '',
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

/// Tarjeta con paisaje de un entorno.
class EnvironmentCard extends StatelessWidget {
  const EnvironmentCard({
    super.key,
    required this.env,
    required this.onTap,
    this.selected = false,
    this.width = 110,
    this.height = 90,
  });
  final AureEnvironment env;
  final VoidCallback onTap;
  final bool selected;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: SceneView(
          env: env,
          borderRadius: 14,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                env.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIconTile extends StatelessWidget {
  const RoundIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.35 : 0.14),
              borderRadius: BorderRadius.circular(16),
              border: selected ? Border.all(color: color, width: 1.5) : null,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
