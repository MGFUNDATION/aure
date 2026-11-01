import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../models/track.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
import 'customize_screen.dart';

/// Inicio (según el diseño): saludo, entorno activo, recomendados
/// y escuchado recientemente.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.watch<LibraryStore>();
    final stats = context.watch<StatsStore>();
    final player = context.watch<PlayerStore>();
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = text.bodySmall?.color?.withValues(alpha: 0.65);

    void mood(String envId, {Duration? sleep}) {
      final env = AureEnvironment.byId(envId);
      s.selectEnvironment(env);
      player.activeEnvId = env.id;
      player.applyMix(env.defaultMix);
      if (sleep != null) player.setSleepTimer(sleep);
      if (lib.tracks.isNotEmpty) {
        player.playTracks(List.of(lib.tracks)..shuffle());
      }
    }

    final ambientOn = player.ambientVolumes.values.any((v) => v > 0.01);

    // Lo escuchado recientemente (sin repetir canciones).
    final seen = <int>{};
    final recent = <Track>[];
    for (final h in stats.history) {
      final t = lib.byId(h['id'] as int);
      if (t != null && seen.add(t.id)) recent.add(t);
      if (recent.length == 5) break;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF1A1C33), Color(0xFF0E0F1F)]
              : s.sunrise
              ? const [Color(0xFFFFF0E4), Color(0xFFFDE7EF)]
              : const [Color(0xFFF7F5FD), Color(0xFFEDF1F9)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              '¡Hola, ${s.userName}! 👋',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '¿Cómo quieres sentirte hoy?',
              style: text.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 20),
            // ---- Entorno activo ----
            SizedBox(
              height: 190,
              child: SceneView(
                env: s.environment,
                customImagePath: s.customBackground,
                brightness: s.illumination * 0.85,
                borderRadius: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.environment.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      shadows: [Shadow(blurRadius: 8)],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ambientOn
                                        ? 'Entorno activo'
                                        : 'Sonidos en pausa',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: ambientOn
                                  ? 'Pausar sonidos del entorno'
                                  : 'Activar sonidos del entorno',
                              icon: Icon(
                                ambientOn ? LucideIcons.x : LucideIcons.play,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => ambientOn
                                  ? player.stopAmbient()
                                  : player.applyMix(
                                      s.ambientMix.isEmpty
                                          ? s.environment.defaultMix
                                          : s.ambientMix,
                                    ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Color.lerp(
                              s.accent,
                              const Color(0xFF2C5E7A),
                              0.45,
                            )!.withValues(alpha: 0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomizeScreen(),
                            ),
                          ),
                          child: const Text(
                            'Cambiar entorno',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Recomendado para ti',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MoodTile(
                  icon: LucideIcons.focus,
                  label: 'Focus',
                  color: AurePalette.green,
                  onTap: () => mood('bosque'),
                ),
                const SizedBox(width: 10),
                _MoodTile(
                  icon: LucideIcons.waves,
                  label: 'Relajación',
                  color: AurePalette.cyan,
                  onTap: () => mood('playa'),
                ),
                const SizedBox(width: 10),
                _MoodTile(
                  icon: LucideIcons.moonStar,
                  label: 'Sueño',
                  color: AurePalette.blue,
                  onTap: () =>
                      mood('espacio', sleep: const Duration(minutes: 30)),
                ),
                const SizedBox(width: 10),
                _MoodTile(
                  icon: LucideIcons.sparkles,
                  label: 'Energía',
                  color: AurePalette.purple,
                  onTap: () => mood('ciudad'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'Escuchado recientemente',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              _EmptyRecent(lib: lib, muted: muted)
            else
              for (final t in recent)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      player.playTracks(recent, start: recent.indexOf(t)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Artwork(track: t, size: 50, radius: 10),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fmtMinutes(t.duration.inSeconds / 60),
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.rotateCw, size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.92,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        color.withValues(alpha: 0.22),
                        color.withValues(alpha: 0.06),
                      ]
                    : [
                        color.withValues(alpha: 0.16),
                        color.withValues(alpha: 0.05),
                      ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: dark ? Colors.white : color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.lib, required this.muted});
  final LibraryStore lib;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final msg = lib.loading
        ? 'Buscando tu música…'
        : lib.permissionDenied
        ? 'Aure necesita permiso para leer tu música.'
        : lib.tracks.isEmpty
        ? 'No encontré canciones en el teléfono todavía.'
        : 'Reproduce algo y aparecerá aquí.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(msg, style: TextStyle(color: muted)),
          ),
          if (!lib.loading && (lib.permissionDenied || lib.tracks.isEmpty))
            TextButton(onPressed: lib.scan, child: const Text('Buscar música')),
        ],
      ),
    );
  }
}
