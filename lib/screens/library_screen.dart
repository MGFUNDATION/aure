import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../widgets/common.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Biblioteca'),
          actions: [
            IconButton(
              tooltip: 'Volver a buscar música',
              onPressed: lib.scan,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Canciones'),
              Tab(text: 'Álbumes'),
              Tab(text: 'Artistas'),
              Tab(text: 'Descargas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _PlaylistsTab(),
            _TrackList(tracks: lib.tracks),
            _GroupList(groups: lib.byAlbum, icon: Icons.album),
            _GroupList(groups: lib.byArtist, icon: Icons.person),
            _TrackList(
              tracks: lib.downloads,
              emptyText:
                  'Aquí aparecen las canciones libres que descargues desde Aure IA.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, this.emptyText});
  final List<Track> tracks;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    final p = context.read<PlayerStore>();
    if (lib.loading) return const Center(child: CircularProgressIndicator());
    if (tracks.isEmpty) {
      return EmptyState(
        icon: Icons.music_off,
        text:
            emptyText ??
            (lib.permissionDenied
                ? 'Dale permiso a Aure para leer tu música.'
                : 'No hay canciones aquí todavía.'),
        action: emptyText == null
            ? FilledButton(
                onPressed: lib.scan,
                child: const Text('Buscar música'),
              )
            : null,
      );
    }
    return ListView.builder(
      itemCount: tracks.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Text('${tracks.length} canciones'),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.shuffle),
                  onPressed: () => p.playTracks(List.of(tracks)..shuffle()),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => p.playTracks(tracks),
                ),
              ],
            ),
          );
        }
        final t = tracks[i - 1];
        return TrackTile(
          track: t,
          onTap: () => p.playTracks(tracks, start: i - 1),
        );
      },
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups, required this.icon});
  final Map<String, List<Track>> groups;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final keys = groups.keys.toList()..sort();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final list = groups[k]!;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Artwork(track: list.first),
          title: Text(k, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${list.length} canciones'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(k)),
                body: _TrackList(tracks: list),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.tonalIcon(
            onPressed: () async {
              final name = await promptText(context, 'Nueva playlist');
              if (name != null && name.isNotEmpty) lib.createPlaylist(name);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva playlist'),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          title: const Text('Mis favoritos'),
          subtitle: Text('${lib.favorites.length} canciones'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Mis favoritos')),
                body: _TrackList(tracks: lib.favoriteTracks),
              ),
            ),
          ),
        ),
        for (final p in lib.playlists)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Artwork(
              track: lib.tracksOf(p).isEmpty ? null : lib.tracksOf(p).first,
            ),
            title: Text(p.name),
            subtitle: Text('${p.trackIds.length} canciones'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'rename') {
                  final n = await promptText(
                    context,
                    'Renombrar',
                    initial: p.name,
                  );
                  if (n != null && n.isNotEmpty) lib.renamePlaylist(p, n);
                } else if (v == 'delete') {
                  lib.deletePlaylist(p);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _PlaylistDetail(playlist: p)),
            ),
          ),
      ],
    );
  }
}

class _PlaylistDetail extends StatelessWidget {
  const _PlaylistDetail({required this.playlist});
  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    final tracks = lib.tracksOf(playlist);
    final p = context.read<PlayerStore>();
    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: tracks.isEmpty
          ? const EmptyState(
              icon: Icons.queue_music,
              text: 'Añade canciones desde el menú ⋮ de cualquier canción.',
            )
          : ListView(
              children: [
                for (var i = 0; i < tracks.length; i++)
                  TrackTile(
                    track: tracks[i],
                    onTap: () => p.playTracks(tracks, start: i),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          lib.removeFromPlaylist(playlist, tracks[i].id),
                    ),
                  ),
              ],
            ),
    );
  }
}
