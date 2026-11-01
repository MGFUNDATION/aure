import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../models/track.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../state/stats_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/common.dart';
import 'ai_chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    final player = context.read<PlayerStore>();
    final settings = context.watch<SettingsStore>();
    final stats = context.watch<StatsStore>();
    final text = Theme.of(context).textTheme;

    final searching = _query.trim().isNotEmpty;
    final results = searching ? lib.search(_query) : const <Track>[];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Explorar',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _q,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar artistas, canciones, entornos…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Tararea para buscar',
                  icon: const Icon(Icons.mic_none),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiChatScreen(startHumming: true),
                    ),
                  ),
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (searching) ...[
            SectionHeader('En tu teléfono (${results.length})'),
            ...results
                .take(50)
                .map(
                  (t) => TrackTile(
                    track: t,
                    onTap: () => player.playTracks(
                      List.of(results),
                      start: results.indexOf(t),
                    ),
                  ),
                ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.auto_awesome),
              title: Text('Buscar "$_query" en música libre'),
              subtitle: const Text('Con Aure IA'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AiChatScreen(initialMessage: 'buscar $_query'),
                ),
              ),
            ),
          ] else ...[
            const SectionHeader('Entornos destacados'),
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
                        width: 120,
                        height: 105,
                        selected: settings.envId == e.id,
                        onTap: () {
                          settings.selectEnvironment(e);
                          player.activeEnvId = e.id;
                          player.applyMix(e.defaultMix);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SectionHeader('Categorías'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in _categories)
                    RoundIconTile(
                      icon: c.$2,
                      label: c.$1,
                      color: c.$3,
                      onTap: () {
                        final e = AureEnvironment.byId(c.$4);
                        settings.selectEnvironment(e);
                        player.activeEnvId = e.id;
                        player.applyMix(e.defaultMix);
                      },
                    ),
                ],
              ),
            ),
            if (lib.tracks.isNotEmpty) ...[
              const SectionHeader('Artistas en tu teléfono'),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final e in lib.byArtist.entries.take(20))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () => player.playTracks(e.value),
                          child: Column(
                            children: [
                              ClipOval(
                                child: Artwork(
                                  track: e.value.first,
                                  size: 60,
                                  radius: 30,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  e.key,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SectionHeader('Lo que más escuchas'),
            if (stats.top('trackSecs').isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Aún no hay datos. ¡Dale play!'),
              ),
            for (final e in stats.top('trackSecs'))
              if (lib.byId(int.parse(e.key)) case final t?)
                TrackTile(track: t, onTap: () => player.playTracks([t])),
          ],
        ],
      ),
    );
  }

  static const _categories = [
    ('Naturaleza', Icons.park_outlined, AurePalette.green, 'bosque'),
    ('Ciudad', Icons.location_city, AurePalette.blue, 'ciudad'),
    ('Relajación', Icons.spa_outlined, AurePalette.pink, 'playa'),
    ('Concentración', Icons.center_focus_strong, AurePalette.cyan, 'montana'),
    ('Aventura', Icons.local_fire_department, AurePalette.orange, 'cabana'),
    ('Sueño', Icons.nightlight_round, AurePalette.violet, 'espacio'),
  ];
}
