import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/shell.dart';
import 'state/audio_handler.dart';
import 'state/library_store.dart';
import 'state/player_store.dart';
import 'state/settings_store.dart';
import 'state/stats_store.dart';
import 'theme/aure_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final handler = await AudioService.init(
    builder: AureAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.aure.app.audio',
      androidNotificationChannelName: 'Reproducción de Aure',
      androidNotificationOngoing: true,
    ),
  );

  final settings = SettingsStore(prefs);
  final stats = StatsStore(prefs);
  final library = LibraryStore(prefs);
  final player = PlayerStore(handler, stats)..activeEnvId = settings.envId;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: stats),
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: player),
      ],
      child: const AureApp(),
    ),
  );

  library.scan();
}

class AureApp extends StatelessWidget {
  const AureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return MaterialApp(
      title: 'Aure',
      debugShowCheckedModeBanner: false,
      themeMode: s.themeMode,
      theme: AureTheme.build(
        brightness: Brightness.light,
        accent: s.accent,
        fontScale: s.fontScale,
      ),
      darkTheme: AureTheme.build(
        brightness: Brightness.dark,
        accent: s.accent,
        fontScale: s.fontScale,
      ),
      home: const AureShell(),
    );
  }
}
