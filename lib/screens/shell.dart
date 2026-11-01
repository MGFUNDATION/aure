import 'package:flutter/material.dart';

import '../widgets/mini_player.dart';
import 'ai_chat_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Navegación principal: Inicio · Explorar · [IA] · Biblioteca · Perfil
class AureShell extends StatefulWidget {
  const AureShell({super.key});

  @override
  State<AureShell> createState() => _AureShellState();
}

class _AureShellState extends State<AureShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    ExploreScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  void _openAi() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    // El botón central (IA) no es una pestaña: abre el chat.
    final navIndex = _index >= 2 ? _index + 1 : _index;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: navIndex,
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              if (i == 2) return _openAi();
              setState(() => _index = i > 2 ? i - 1 : i);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                label: 'Aure IA',
              ),
              const NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Biblioteca',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
