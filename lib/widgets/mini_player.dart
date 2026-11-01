import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/player_screen.dart';
import '../state/player_store.dart';
import 'common.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerStore>();
    final t = p.current;
    if (t == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(PlayerScreen.route()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Artwork(track: t, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    t.displayArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                p.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: p.togglePlay,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: p.next,
            ),
          ],
        ),
      ),
    );
  }
}
