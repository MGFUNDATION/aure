import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../state/library_store.dart';
import '../state/stats_store.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsStore>();
    final lib = context.watch<LibraryStore>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final current = stats.minutesInRange(_days);
    final previous = stats.minutesInRange(_days, offsetDays: _days);
    final change = previous == 0
        ? null
        : ((current - previous) / previous * 100).round();
    final series = stats.lastDays(_days == 7 ? 7 : 30);
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final peak = stats.peakHour;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          DropdownButton<int>(
            value: _days,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 7, child: Text('Esta semana')),
              DropdownMenuItem(value: 30, child: Text('Este mes')),
            ],
            onChanged: (v) => setState(() => _days = v!),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiempo de escucha'),
                  const SizedBox(height: 4),
                  Text(
                    fmtMinutes(current),
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (change != null)
                    Text(
                      '${change >= 0 ? '+' : ''}$change% vs periodo anterior',
                      style: TextStyle(
                        color: change >= 0 ? Colors.green : Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: _Bars(
                      values: series.map((e) => e.value).toList(),
                      labels: series
                          .map(
                            (e) => _days == 7
                                ? dayNames[e.key.weekday - 1]
                                : (e.key.day % 5 == 0 ? '${e.key.day}' : ''),
                          )
                          .toList(),
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  'Sesiones de enfoque',
                  '${stats.focusSessions}',
                  Icons.center_focus_strong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  'Hora favorita',
                  peak == null ? '—' : '${peak.toString().padLeft(2, '0')}:00',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  'Total escuchado',
                  fmtMinutes(stats.totalMinutes),
                  Icons.headphones,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  'Reproducciones',
                  '${stats.totalPlays}',
                  Icons.play_circle,
                ),
              ),
            ],
          ),
          _TopList(
            title: 'Entornos más usados',
            entries: stats.top('envSecs'),
            label: (k) => AureEnvironment.byId(k).name,
          ),
          _TopList(
            title: 'Artistas favoritos',
            entries: stats.top('artistSecs'),
            label: (k) => k,
          ),
          _TopList(
            title: 'Canciones más escuchadas',
            entries: stats.top('trackSecs'),
            label: (k) => lib.byId(int.parse(k))?.title ?? 'Canción eliminada',
          ),
          _TopList(
            title: 'Géneros',
            entries: stats.top('genreSecs'),
            label: (k) => k,
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.labels,
    required this.color,
  });
  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(1, (a, b) => b > a ? b : a);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: (values[i] / max).clamp(0.03, 1.0),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: values.length > 10 ? 1 : 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [color.withValues(alpha: 0.5), color],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _TopList extends StatelessWidget {
  const _TopList({
    required this.title,
    required this.entries,
    required this.label,
  });
  final String title;
  final List<MapEntry<String, double>> entries;
  final String Function(String key) label;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final max = entries.first.value;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label(e.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          fmtMinutes(e.value / 60),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: e.value / max,
                      borderRadius: BorderRadius.circular(4),
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
