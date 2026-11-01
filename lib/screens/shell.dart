import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/mini_player.dart';
import 'ai_chat_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Navegación principal: Inicio · Explorar · Buscar (Aure IA) · Biblioteca · Perfil
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
    AiChatScreen(asTab: true),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.house),
                selectedIcon: Icon(LucideIcons.house),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.compass),
                selectedIcon: Icon(LucideIcons.compass),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.search),
                selectedIcon: Icon(LucideIcons.search),
                label: 'Buscar',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.libraryBig),
                selectedIcon: Icon(LucideIcons.libraryBig),
                label: 'Biblioteca',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.user),
                selectedIcon: Icon(LucideIcons.user),
                label: 'Perfil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
