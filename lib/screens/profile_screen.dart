import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
import 'customize_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'wellness_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.watch<LibraryStore>();
    final stats = context.watch<StatsStore>();
    final text = Theme.of(context).textTheme;
    void go(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  'Perfil',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => go(const SettingsScreen()),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 70,
                  child: GestureDetector(
                    onTap: () async {
                      final img = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) {
                        s.update((s) => s.profileCoverPath = img.path);
                      }
                    },
                    child: SceneView(
                      env: s.environment,
                      customImagePath: s.profileCoverPath ?? s.customBackground,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final img = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) s.update((s) => s.avatarPath = img.path);
                    },
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: s.accent,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: s.avatarPath != null
                            ? FileImage(File(s.avatarPath!))
                            : null,
                        child: s.avatarPath == null
                            ? Text(
                                s.userName.isEmpty ? '?' : s.userName[0],
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 136,
                  right: 12,
                  bottom: 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.userName,
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(s.userHandle, style: text.bodySmall),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editProfile(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text('"${s.bio}"', style: text.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _Stat(
                  Icons.queue_music,
                  'Playlists',
                  '${lib.playlists.length}',
                ),
                _Stat(Icons.music_note, 'Canciones', '${lib.tracks.length}'),
                _Stat(
                  Icons.favorite_border,
                  'Favoritas',
                  '${lib.favorites.length}',
                ),
                _Stat(Icons.headphones, 'Escuchas', '${stats.totalPlays}'),
              ],
            ),
          ),
          SectionHeader(
            'Mi universo',
            action: 'Personalizar',
            onAction: () => go(const CustomizeScreen()),
          ),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in AureEnvironment.all)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: EnvironmentCard(
                      env: e,
                      width: 90,
                      height: 105,
                      selected: s.envId == e.id,
                      onTap: () {
                        s.selectEnvironment(e);
                        context.read<PlayerStore>()
                          ..activeEnvId = e.id
                          ..applyMix(e.defaultMix);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader('Mi espacio'),
          _Section(
            Icons.insights,
            'Estadísticas',
            'Datos de tu escucha y tus favoritos',
            AurePalette.purple,
            () => go(const StatsScreen()),
          ),
          _Section(
            Icons.self_improvement,
            'Bienestar',
            'Ánimo, rutinas y enfoque',
            AurePalette.green,
            () => go(const WellnessScreen()),
          ),
          _Section(
            Icons.history,
            'Actividad reciente',
            'Tu historial de reproducciones',
            AurePalette.pink,
            () => go(const _HistoryScreen()),
          ),
          _Section(
            Icons.palette_outlined,
            'Temas y colores',
            'Claro, oscuro, color principal',
            AurePalette.orange,
            () => go(const CustomizeScreen(initialTab: 2)),
          ),
          _Section(
            Icons.settings_outlined,
            'Ajustes',
            'Descargas, letras y privacidad',
            AurePalette.blue,
            () => go(const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final s = context.read<SettingsStore>();
    final name = TextEditingController(text: s.userName);
    final handle = TextEditingController(text: s.userHandle);
    final bio = TextEditingController(text: s.bio);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: handle,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: bio,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Frase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              s.update((s) {
                s.userName = name.text.trim();
                s.userHandle = handle.text.trim();
                s.bio = bio.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.icon, this.title, this.subtitle, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsStore>();
    final lib = context.watch<LibraryStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Actividad reciente')),
      body: stats.history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              text: 'Todavía no hay actividad.',
            )
          : ListView(
              children: [
                for (final h in stats.history)
                  ListTile(
                    leading: Artwork(track: lib.byId(h['id'] as int)),
                    title: Text('Escuchaste ${h['title']}'),
                    subtitle: Text(
                      '${h['artist']} · ${_ago(DateTime.parse(h['at'] as String))}',
                    ),
                    onTap: () {
                      final t = lib.byId(h['id'] as int);
                      if (t != null) {
                        context.read<PlayerStore>().playTracks([t]);
                      }
                    },
                  ),
              ],
            ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }
}
