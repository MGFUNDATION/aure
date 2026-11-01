import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/scene_view.dart';

class _Mood {
  const _Mood(this.emoji, this.label, this.envId, this.tip);
  final String emoji;
  final String label;
  final String envId;
  final String tip;
}

const _moods = [
  _Mood(
    '😟',
    'Ansioso',
    'playa',
    'Respira con olas suaves. Prueba la respiración 4-7-8.',
  ),
  _Mood(
    '😴',
    'Cansado',
    'cabana',
    'Una fogata cálida y música tranquila para recargar.',
  ),
  _Mood(
    '🧐',
    'Enfocado',
    'bosque',
    'Bosque y río: perfecto para concentrarte.',
  ),
  _Mood('😌', 'Relajado', 'aurora', 'Disfruta el momento bajo la aurora.'),
  _Mood('😄', 'Feliz', 'ciudad', '¡Sube la energía con tu música favorita!'),
];

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  void _applyEnv(
    BuildContext context,
    String envId, {
    bool shuffleMusic = true,
  }) {
    final env = AureEnvironment.byId(envId);
    final s = context.read<SettingsStore>();
    final p = context.read<PlayerStore>();
    final lib = context.read<LibraryStore>();
    s.selectEnvironment(env);
    p.activeEnvId = env.id;
    p.applyMix(env.defaultMix);
    if (shuffleMusic && lib.tracks.isNotEmpty) {
      p.playTracks(List.of(lib.tracks)..shuffle());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsStore>();
    final lastMood = stats.moods.isEmpty
        ? null
        : stats.moods.first['mood'] as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Bienestar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Cómo te sientes hoy?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Text(
                    'Elige tu estado y te recomiendo el mejor entorno.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final m in _moods)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            stats.logMood(m.label);
                            _applyEnv(context, m.envId);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(m.tip)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              children: [
                                Text(
                                  m.emoji,
                                  style: const TextStyle(fontSize: 30),
                                ),
                                Text(
                                  m.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: lastMood == m.label
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              'Rutinas recomendadas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          _Routine(
            icon: Icons.wb_sunny_outlined,
            color: AurePalette.orange,
            title: 'Mañana productiva',
            subtitle: '45 min de enfoque en la montaña',
            onTap: () {
              _applyEnv(context, 'montana');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FocusTimerScreen(minutes: 45),
                ),
              );
            },
          ),
          _Routine(
            icon: Icons.timer_outlined,
            color: AurePalette.violet,
            title: 'Pomodoro',
            subtitle: '25 min de enfoque + 5 de descanso',
            onTap: () {
              _applyEnv(context, 'bosque');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FocusTimerScreen(minutes: 25),
                ),
              );
            },
          ),
          _Routine(
            icon: Icons.spa_outlined,
            color: AurePalette.pink,
            title: 'Pausa relajante',
            subtitle: '20 min en la playa',
            onTap: () {
              _applyEnv(context, 'playa');
              context.read<PlayerStore>().setSleepTimer(
                const Duration(minutes: 20),
              );
            },
          ),
          _Routine(
            icon: Icons.nightlight_round,
            color: AurePalette.blue,
            title: 'Sueño profundo',
            subtitle: 'Noche estrellada; la música se apaga sola en 45 min',
            onTap: () {
              _applyEnv(context, 'espacio');
              context.read<PlayerStore>().setSleepTimer(
                const Duration(minutes: 45),
              );
            },
          ),
          _Routine(
            icon: Icons.self_improvement,
            color: AurePalette.green,
            title: 'Respiración guiada',
            subtitle: '4-7-8 · 5 minutos',
            onTap: () {
              _applyEnv(context, 'aurora', shuffleMusic: false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BreathingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Routine extends StatelessWidget {
  const _Routine({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: onTap,
    ),
  );
}

// ---------------- Temporizador de enfoque ----------------

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key, required this.minutes});
  final int minutes;

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late Duration _left = Duration(minutes: widget.minutes);
  Timer? _timer;
  bool _running = false;

  void _toggle() {
    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _left -= const Duration(seconds: 1));
        if (_left <= Duration.zero) {
          _timer?.cancel();
          context.read<StatsStore>().addFocusSession(widget.minutes);
          _running = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Sesión completada! Tómate un descanso.'),
            ),
          );
          setState(() => _left = Duration(minutes: widget.minutes));
        }
      });
    }
    setState(() => _running = !_running);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final total = widget.minutes * 60;
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = _left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(foregroundColor: Colors.white),
      body: SceneView(
        env: s.environment,
        customImagePath: s.customBackground,
        brightness: 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - _left.inSeconds / total,
                      strokeWidth: 8,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    Center(
                      child: Text(
                        '$mm:$ss',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pausar' : 'Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Respiración 4-7-8 ----------------

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  // 4 s inhalar, 7 s sostener, 8 s exhalar = 19 s por ciclo.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 19),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(foregroundColor: Colors.white),
      body: SceneView(
        env: s.environment,
        customImagePath: s.customBackground,
        brightness: 0.55,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = _c.value * 19;
            String label;
            double scale;
            if (t < 4) {
              label = 'Inhala';
              scale = 0.5 + 0.5 * (t / 4);
            } else if (t < 11) {
              label = 'Sostén';
              scale = 1;
            } else {
              label = 'Exhala';
              scale = 1 - 0.5 * ((t - 11) / 8);
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            s.accent.withValues(alpha: 0.9),
                            s.accent.withValues(alpha: 0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: s.accent.withValues(alpha: 0.6),
                            blurRadius: 40 * scale + 10,
                            spreadRadius: 4 * sin(scale),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
