import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
import 'customize_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'wellness_screen.dart';

/// Panel principal del perfil (según el diseño de G-Mitch):
/// foto centrada, nombre, usuario, contadores, "Editar perfil" y secciones.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.watch<LibraryStore>();
    final stats = context.watch<StatsStore>();
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    void go(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xFF14152B), const Color(0xFF0E0F1F)]
              : [const Color(0xFFF7F5FD), const Color(0xFFEDF1F9)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ---- Barra superior: Perfil · ajustes · campana ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Text(
                    'Perfil',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Ajustes',
                    icon: const Icon(LucideIcons.settings),
                    onPressed: () => go(const SettingsScreen()),
                  ),
                  IconButton(
                    tooltip: 'Actividad',
                    icon: const Icon(LucideIcons.bell),
                    onPressed: () => go(const _HistoryScreen()),
                  ),
                ],
              ),
            ),
            // ---- Portada ondulada + foto + nombre ----
            SizedBox(
              height: 272,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 215,
                    child: GestureDetector(
                      onTap: () => _pickCover(context),
                      child: ClipPath(
                        clipper: _WaveClipper(),
                        child: SceneView(
                          env: s.environment,
                          customImagePath: s.profileCoverPath,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 128,
                    child: GestureDetector(
                      onTap: () => _pickAvatar(context),
                      child: Container(
                        width: 118,
                        height: 118,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [scheme.primary, AurePalette.purple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dark
                                ? const Color(0xFF26274A)
                                : const Color(0xFFEDE7FD),
                            border: Border.all(
                              color: dark
                                  ? const Color(0xFF14152B)
                                  : Colors.white,
                              width: 3,
                            ),
                            image: s.avatarPath != null
                                ? DecorationImage(
                                    image: FileImage(File(s.avatarPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: s.avatarPath == null
                              ? Text(
                                  s.userName.isEmpty
                                      ? '?'
                                      : s.userName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 148,
                    right: 12,
                    top: 162,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.userName,
                                overflow: TextOverflow.ellipsis,
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.badgeCheck,
                              size: 22,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                        Text(
                          s.userHandle,
                          style: text.bodyMedium?.copyWith(
                            color: text.bodyMedium?.color?.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, AurePalette.purple],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.crown,
                                size: 14,
                                color: AurePalette.gold,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Miembro Aure',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ---- Frase + lápiz ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '"${s.bio}"',
                      style: text.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _editProfile(context),
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(LucideIcons.pencil, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ---- Tarjetas de contadores ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _StatCard(
                    LucideIcons.music,
                    AurePalette.violet,
                    'Playlists',
                    '${lib.playlists.length}',
                  ),
                  _StatCard(
                    LucideIcons.heart,
                    AurePalette.pink,
                    'Favoritas',
                    '${lib.favorites.length}',
                  ),
                  _StatCard(
                    LucideIcons.disc3,
                    AurePalette.green,
                    'Canciones',
                    _compact(lib.tracks.length),
                  ),
                  _StatCard(
                    LucideIcons.headphones,
                    AurePalette.purple,
                    'Escuchas',
                    _compact(stats.totalPlays),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ---- Secciones ----
            _Row(
              LucideIcons.mountain,
              'Entornos guardados',
              () => go(const CustomizeScreen()),
            ),
            _Row(
              LucideIcons.alarmClock,
              'Historial',
              () => go(const _HistoryScreen()),
            ),
            _Row(
              LucideIcons.download,
              'Descargas',
              () => go(
                Scaffold(
                  appBar: AppBar(title: const Text('Descargas')),
                  body: TrackListView(
                    tracks: lib.downloads,
                    emptyText:
                        'Aquí aparecen las canciones libres que descargues desde Aure IA.',
                  ),
                ),
              ),
            ),
            _Row(
              LucideIcons.slidersHorizontal,
              'Mezclas personalizadas',
              () => showAmbientSheet(context),
            ),
            _Row(
              LucideIcons.chartColumn,
              'Estadísticas',
              () => go(const StatsScreen()),
            ),
            _Row(
              LucideIcons.flower2,
              'Bienestar',
              () => go(const WellnessScreen()),
            ),
            _Row(
              LucideIcons.settings,
              'Ajustes',
              () => go(const SettingsScreen()),
            ),
            _Row(
              LucideIcons.circleHelp,
              'Ayuda y soporte',
              () => go(const _HelpScreen()),
            ),
          ],
        ),
      ),
    );
  }

  static String _compact(int n) {
    if (n < 1000) return '$n';
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  Future<void> _pickCover(BuildContext context) async {
    final s = context.read<SettingsStore>();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) s.update((s) => s.profileCoverPath = img.path);
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final s = context.read<SettingsStore>();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) s.update((s) => s.avatarPath = img.path);
  }

  Future<void> _editProfile(BuildContext context) async {
    final s = context.read<SettingsStore>();
    final name = TextEditingController(text: s.userName);
    final handle = TextEditingController(text: s.userHandle);
    final bio = TextEditingController(text: s.bio);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Editar perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickAvatar(context),
              icon: const Icon(LucideIcons.camera),
              label: const Text('Cambiar foto'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickCover(context),
              icon: const Icon(LucideIcons.image),
              label: const Text('Cambiar portada'),
            ),
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
            const SizedBox(height: 16),
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.color, this.label, this.value);
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE9E6F3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Borde inferior ondulado de la portada (como en el diseño).
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.56)
      ..cubicTo(w * 0.72, h * 0.48, w * 0.52, h * 0.56, w * 0.4, h * 0.68)
      ..cubicTo(w * 0.27, h * 0.84, w * 0.13, h * 0.97, 0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    minTileHeight: 52,
    leading: Icon(icon, size: 22),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    trailing: const Icon(LucideIcons.chevronRight, size: 18),
    onTap: onTap,
  );
}

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  static const _faq = [
    (
      'No aparece mi música',
      'Da permiso de "Música y audio" a Aure en los ajustes del teléfono y toca "Buscar música" en la Biblioteca.',
    ),
    (
      '¿Cómo pongo la letra de una canción?',
      'Aure la busca sola si tienes internet. Sin conexión, coloca un archivo .lrc con el mismo nombre junto a la canción.',
    ),
    (
      '¿Cómo reconozco una canción tarareando?',
      'Ve a Buscar, toca el micrófono y tararea o canta unos 10 segundos.',
    ),
    (
      '¿Por qué veo un anuncio al descargar?',
      'Solo hay un anuncio corto por cada canción libre que descargas gratis. Así apoyas el proyecto. No hay más anuncios en la app.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayuda y soporte')),
    body: ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final f in _faq)
          ExpansionTile(
            title: Text(f.$1),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(f.$2)],
          ),
      ],
    ),
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
