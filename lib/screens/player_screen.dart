import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../services/lyrics_service.dart';
import '../state/library_store.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
import 'customize_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => const PlayerScreen(),
    transitionsBuilder: (_, a, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerStore>();
    final s = context.watch<SettingsStore>();
    final lib = context.watch<LibraryStore>();
    final t = p.current;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    if (t == null) {
      return const Scaffold(body: Center(child: Text('Nada sonando')));
    }

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s.showSceneInPlayer)
                  SceneView(
                    env: s.environment,
                    customImagePath: s.customBackground,
                    brightness: s.illumination,
                  )
                else
                  Center(
                    child: Artwork(
                      track: t,
                      size: size.width * 0.7,
                      radius: 24,
                    ),
                  ),
                SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            s.environment.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              shadows: [Shadow(blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomizeScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              t.displayArtist,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          lib.isFavorite(t.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: lib.isFavorite(t.id) ? scheme.primary : null,
                        ),
                        onPressed: () => lib.toggleFavorite(t.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Duration>(
                    stream: p.position,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final dur = p.duration;
                      final max = dur.inMilliseconds.toDouble().clamp(
                        1.0,
                        double.infinity,
                      );
                      return Column(
                        children: [
                          Slider(
                            value: pos.inMilliseconds.toDouble().clamp(0, max),
                            max: max,
                            onChanged: (v) =>
                                p.seek(Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fmtDuration(pos),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  fmtDuration(dur),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: p.shuffle ? scheme.primary : null,
                        ),
                        onPressed: p.toggleShuffle,
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: p.previous,
                      ),
                      GestureDetector(
                        onTap: p.togglePlay,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.45),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            p.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: p.next,
                      ),
                      IconButton(
                        icon: Icon(
                          p.loop == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: p.loop == LoopMode.off ? null : scheme.primary,
                        ),
                        onPressed: p.cycleLoop,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Action(Icons.landscape_outlined, 'Entorno', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomizeScreen(),
                          ),
                        );
                      }),
                      _Action(
                        Icons.graphic_eq,
                        'Sonidos',
                        () => showAmbientSheet(context),
                      ),
                      _Action(
                        Icons.lyrics_outlined,
                        'Letra',
                        () => showLyricsSheet(context),
                      ),
                      _Action(
                        Icons.bedtime_outlined,
                        p.sleepAt == null ? 'Dormir' : 'Timer ✓',
                        () => showSleepSheet(context),
                      ),
                      _Action(
                        Icons.playlist_add,
                        'Playlist',
                        () => showAddToPlaylist(context, t),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

// ---------------- Sonidos ambientales ----------------

void showAmbientSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const AmbientMixer(),
  );
}

class AmbientMixer extends StatelessWidget {
  const AmbientMixer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerStore>();
    final s = context.read<SettingsStore>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sonidos ambientales',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (final a in AmbientSound.values)
              Row(
                children: [
                  Icon(a.icon, size: 20),
                  const SizedBox(width: 8),
                  SizedBox(width: 64, child: Text(a.label)),
                  Expanded(
                    child: Slider(
                      value: p.ambientVolumes[a] ?? 0,
                      onChanged: (v) {
                        p.setAmbient(a, v);
                        s.update(
                          (s) => s.ambientMix = Map.of(p.ambientVolumes),
                        );
                      },
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                const Icon(Icons.volume_up, size: 20),
                const SizedBox(width: 8),
                const SizedBox(width: 64, child: Text('General')),
                Expanded(
                  child: Slider(
                    value: p.ambientMaster,
                    onChanged: p.setAmbientMaster,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: p.stopAmbient,
                icon: const Icon(Icons.volume_off),
                label: const Text('Silenciar todo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Temporizador de sueño ----------------

void showSleepSheet(BuildContext context) {
  final p = context.read<PlayerStore>();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Apagar música en…',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          for (final m in [10, 20, 30, 45, 60, 90])
            ListTile(
              title: Text('$m minutos'),
              onTap: () {
                p.setSleepTimer(Duration(minutes: m));
                Navigator.pop(ctx);
              },
            ),
          if (p.sleepAt != null)
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar temporizador'),
              onTap: () {
                p.setSleepTimer(null);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

// ---------------- Letras ----------------

void showLyricsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.85, child: LyricsView()),
  );
}

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _service = LyricsService();
  Future<Lyrics?>? _future;
  int? _trackId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerStore>();
    final s = context.read<SettingsStore>();
    final t = p.current;
    if (t == null) return const SizedBox();
    if (_trackId != t.id) {
      _trackId = t.id;
      _future = _service.find(t, allowOnline: s.onlineFeatures);
    }
    final accent = Theme.of(context).colorScheme.primary;

    return FutureBuilder<Lyrics?>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final l = snap.data;
        if (l == null || l.lines.isEmpty) {
          return const EmptyState(
            icon: Icons.lyrics_outlined,
            text:
                'No encontré la letra de esta canción.\n'
                'Tip: pon un archivo .lrc con el mismo nombre junto a la canción.',
          );
        }
        if (!l.synced) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final line in l.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(line.text, style: const TextStyle(fontSize: 18)),
                ),
              const SizedBox(height: 16),
              Text(
                'Fuente: ${l.source}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }
        return StreamBuilder<Duration>(
          stream: p.position,
          builder: (_, pos) {
            final now = pos.data ?? Duration.zero;
            var active = 0;
            for (var i = 0; i < l.lines.length; i++) {
              if (l.lines[i].time! <= now) active = i;
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              itemCount: l.lines.length,
              itemBuilder: (_, i) {
                final isActive = i == active;
                return GestureDetector(
                  onTap: () => p.seek(l.lines[i].time!),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: isActive ? 24 : 18,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? accent
                          : Theme.of(context).textTheme.bodyLarge?.color
                                ?.withValues(alpha: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l.lines[i].text.isEmpty ? '♪' : l.lines[i].text,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
