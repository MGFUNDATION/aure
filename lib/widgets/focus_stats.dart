import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../screens/stats_screen.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import 'scene_view.dart';

/// Panel "Estadísticas" de Bienestar (según el diseño): tiempo de enfoque
/// con barras por día, sesiones completadas y entornos más usados.
class FocusStatsPanel extends StatefulWidget {
  const FocusStatsPanel({super.key});

  @override
  State<FocusStatsPanel> createState() => _FocusStatsPanelState();
}

class _FocusStatsPanelState extends State<FocusStatsPanel> {
  int _weeksAgo = 0;

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsStore>();
    final text = Theme.of(context).textTheme;

    final minutes = stats.week('focusDaily', weeksAgo: _weeksAgo);
    final prevMinutes = stats.week('focusDaily', weeksAgo: _weeksAgo + 1);
    final sessions = stats.week('focusCount', weeksAgo: _weeksAgo);
    final prevSessions = stats.week('focusCount', weeksAgo: _weeksAgo + 1);

    final total = minutes.fold<double>(0, (a, b) => a + b);
    final prevTotal = prevMinutes.fold<double>(0, (a, b) => a + b);
    final sess = sessions.fold<double>(0, (a, b) => a + b).round();
    final prevSess = prevSessions.fold<double>(0, (a, b) => a + b).round();
    final pct = prevTotal == 0
        ? null
        : ((total - prevTotal) / prevTotal * 100).round();
    final envs = stats.top('envSecs', n: 3);

    void openFull() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Estadísticas',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            PopupMenuButton<int>(
              initialValue: _weeksAgo,
              onSelected: (v) => setState(() => _weeksAgo = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 0, child: Text('Esta semana')),
                PopupMenuItem(value: 1, child: Text('Semana pasada')),
              ],
              child: Row(
                children: [
                  Text(
                    _weeksAgo == 0 ? 'Esta semana' : 'Semana pasada',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronDown, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Tiempo de enfoque', onExpand: openFull),
              const SizedBox(height: 6),
              _BigDuration(total),
              const SizedBox(height: 2),
              _Delta(
                pct == null ? null : '${pct >= 0 ? '+' : ''}$pct%',
                positive: (pct ?? 0) >= 0,
              ),
              const SizedBox(height: 18),
              SizedBox(height: 120, child: _WeekBars(values: minutes)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Sesiones completadas', onExpand: openFull),
              const SizedBox(height: 6),
              Text(
                '$sess',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _Delta(
                prevSess == 0 && sess == 0
                    ? null
                    : '${sess - prevSess >= 0 ? '+' : ''}${sess - prevSess}',
                positive: sess >= prevSess,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Entornos más usados',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(LucideIcons.chartNoAxesColumn, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        if (envs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Escucha música con un entorno activo y aparecerá aquí.',
              style: text.bodySmall,
            ),
          ),
        for (final e in envs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: SceneView(
                    env: AureEnvironment.byId(e.key),
                    borderRadius: 10,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AureEnvironment.byId(e.key).name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  _fmt(e.value / 60),
                  style: TextStyle(
                    fontSize: 13,
                    color: text.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _fmt(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    return h == 0 ? '$m min' : '$h h $m min';
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF26284A), const Color(0xFF1B1C35)]
              : [Colors.white, const Color(0xFFF4F1FD)],
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE8E4F4),
        ),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader(this.title, {required this.onExpand});
  final String title;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onExpand,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF0EDF9),
            ),
            child: const Icon(LucideIcons.maximize2, size: 14),
          ),
        ),
      ],
    );
  }
}

class _BigDuration extends StatelessWidget {
  const _BigDuration(this.minutes);
  final double minutes;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyLarge?.color;
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    const big = TextStyle(fontSize: 30, fontWeight: FontWeight.w700);
    const small = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    return Text.rich(
      TextSpan(
        style: TextStyle(color: color),
        children: [
          if (h > 0) ...[
            TextSpan(text: '$h', style: big),
            const TextSpan(text: ' h ', style: small),
          ],
          TextSpan(text: '$m', style: big),
          const TextSpan(text: ' min', style: small),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.value, {required this.positive});
  final String? value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    if (value == null) {
      return Text(
        'Sin datos de la semana pasada',
        style: TextStyle(fontSize: 12, color: muted),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: positive ? AurePalette.green : AurePalette.pink,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' vs semana pasada',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values});
  final List<double> values;

  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final max = values.fold<double>(1, (a, b) => b > a ? b : a);
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Pista de fondo
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : accent.withValues(alpha: 0.07),
                            ),
                          ),
                          FractionallySizedBox(
                            heightFactor: (values[i] / max).clamp(0.04, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    accent.withValues(alpha: 0.55),
                                    Color.lerp(
                                      accent,
                                      AurePalette.purple,
                                      0.5,
                                    )!,
                                  ],
                                ),
                                boxShadow: values[i] > 0
                                    ? [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_days[i], style: TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
      ],
    );
  }
}
