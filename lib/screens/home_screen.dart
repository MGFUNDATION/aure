import 'package:flutter/material.dart';
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
import 'stats_screen.dart';
import 'wellness_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.watch<LibraryStore>();
    final stats = context.watch<StatsStore>();
    final player = context.read<PlayerStore>();
    final text = Theme.of(context).textTheme;

    void mood(String envId) {
      final env = AureEnvironment.byId(envId);
      s.selectEnvironment(env);
      player.activeEnvId = env.id;
      player.applyMix(env.defaultMix);
      if (lib.tracks.isNotEmpty) {
        player.playTracks(List.of(lib.tracks)..shuffle());
      }
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicio',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_greeting()}, ${s.userName} 👋',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('¿Cómo quieres sentirte hoy?', style: text.bodySmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SizedBox(
              height: 160,
              child: SceneView(
                env: s.environment,
                customImagePath: s.customBackground,
                brightness: s.illumination,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.environment.name,
                        style: text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Entorno activo',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AurePalette.violet,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomizeScreen(),
                          ),
                        ),
                        child: const Text('Cambiar entorno'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader('Para ti'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RoundIconTile(
                  icon: Icons.center_focus_strong,
                  label: 'Enfoque',
                  color: AurePalette.green,
                  onTap: () => mood('bosque'),
                ),
                RoundIconTile(
                  icon: Icons.spa_outlined,
                  label: 'Relajación',
                  color: AurePalette.blue,
                  onTap: () => mood('playa'),
                ),
                RoundIconTile(
                  icon: Icons.nightlight_round,
                  label: 'Sueño',
                  color: AurePalette.violet,
                  onTap: () {
                    mood('espacio');
                    player.setSleepTimer(const Duration(minutes: 30));
                  },
                ),
                RoundIconTile(
                  icon: Icons.bolt,
                  label: 'Energía',
                  color: AurePalette.pink,
                  onTap: () => mood('ciudad'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ShortcutCard(
                    icon: Icons.insights,
                    title: 'Estadísticas',
                    subtitle: 'Hoy: ${fmtMinutes(stats.minutesInRange(1))}',
                    color: AurePalette.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutCard(
                    icon: Icons.self_improvement,
                    title: 'Bienestar',
                    subtitle: 'Rutinas y ánimo',
                    color: AurePalette.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WellnessScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Escuchado recientemente'),
          if (stats.history.isEmpty)
            EmptyState(
              icon: Icons.headphones,
              text: lib.loading
                  ? 'Buscando tu música…'
                  : lib.permissionDenied
                  ? 'Aure necesita permiso para leer tu música.'
                  : lib.tracks.isEmpty
                  ? 'No encontré canciones en el teléfono todavía.'
                  : 'Reproduce algo y aparecerá aquí.',
              action: lib.permissionDenied || lib.tracks.isEmpty
                  ? FilledButton(
                      onPressed: lib.scan,
                      child: const Text('Buscar música'),
                    )
                  : null,
            )
          else
            ...stats.history.take(5).map((h) {
              final t = lib.byId(h['id'] as int);
              if (t == null) return const SizedBox.shrink();
              return TrackTile(track: t, onTap: () => player.playTracks([t]));
            }),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
