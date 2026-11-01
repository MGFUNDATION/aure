import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/config.dart';
import '../state/library_store.dart';
import '../state/settings_store.dart';
import 'customize_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.read<LibraryStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _Header('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.update((s) => s.themeMode = v.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: AccentPicker(
              selected: s.accent,
              onSelected: (c) => s.update((s) => s.accent = c),
            ),
          ),
          ListTile(
            title: const Text('Entorno, fondo e iluminación'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomizeScreen()),
            ),
          ),
          const _Header('Música'),
          ListTile(
            title: const Text('Volver a buscar canciones en el teléfono'),
            leading: const Icon(Icons.refresh),
            onTap: lib.scan,
          ),
          SwitchListTile(
            title: const Text('Buscar letras automáticamente'),
            value: s.autoLyrics,
            onChanged: (v) => s.update((s) => s.autoLyrics = v),
          ),
          SwitchListTile(
            title: const Text('Funciones en línea'),
            subtitle: const Text(
              'Letras, reconocimiento y música libre. Apágalo para usar Aure 100% sin internet.',
            ),
            value: s.onlineFeatures,
            onChanged: (v) => s.update((s) => s.onlineFeatures = v),
          ),
          const _Header('Descargas libres'),
          RadioGroup<DownloadQuality>(
            groupValue: s.downloadQuality,
            onChanged: (v) => s.update((s) => s.downloadQuality = v!),
            child: Column(
              children: [
                for (final q in DownloadQuality.values)
                  RadioListTile<DownloadQuality>(
                    title: Text('Calidad ${q.label.toLowerCase()}'),
                    subtitle: Text(q.detail),
                    value: q,
                  ),
              ],
            ),
          ),
          const _Header('Servicios'),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Reconocer por tarareo'),
            subtitle: Text(AureConfig.hasAcr ? 'Activo' : 'Sin configurar'),
          ),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Catálogo Jamendo'),
            subtitle: Text(
              AureConfig.hasJamendo
                  ? 'Activo'
                  : 'Sin configurar (Internet Archive sí está activo)',
            ),
          ),
          const _Header('Acerca de Aure'),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Tus datos se quedan en tu teléfono'),
            subtitle: Text(
              'Estadísticas, ánimo e historial nunca salen del dispositivo.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.volunteer_activism_outlined),
            title: Text('Sin anuncios que interrumpan'),
            subtitle: Text(
              'Solo verás un anuncio corto, si tú lo eliges, al descargar una canción gratis. Así apoyas el proyecto.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión'),
            subtitle: Text('0.1.0'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
