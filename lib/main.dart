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

  // Si algo falla al arrancar, mostramos el error en pantalla en vez de cerrar.
  ErrorWidget.builder = (details) => _StartupError(details.exceptionAsString());

  try {
    await _start();
  } catch (e, st) {
    debugPrint('Aure no pudo iniciar: $e\n$st');
    runApp(_StartupError('$e'));
  }
}

Future<AureAudioHandler> _initAudio() async {
  try {
    return await AudioService.init(
      builder: AureAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.aure.app.audio',
        androidNotificationChannelName: 'Reproducción de Aure',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(const Duration(seconds: 8));
  } catch (e) {
    // Sin servicio en segundo plano la música igual suena con la app abierta.
    debugPrint('AudioService no disponible: $e');
    return AureAudioHandler();
  }
}

Future<void> _start() async {
  final prefs = await SharedPreferences.getInstance();
  final handler = await _initAudio();

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

class _StartupError extends StatelessWidget {
  const _StartupError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: AurePalette.darkBg,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Aure tuvo un problema al iniciar.\n\n$message',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    ),
  );
}

class AureApp extends StatelessWidget {
  const AureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return MaterialApp(
      title: 'Aure',
      debugShowCheckedModeBanner: false,
      themeMode: s.effectiveThemeMode,
      theme: AureTheme.build(
        brightness: Brightness.light,
        accent: s.accent,
        fontScale: s.fontScale,
        sunrise: s.sunrise,
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
