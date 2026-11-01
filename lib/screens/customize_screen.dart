import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/environment.dart';
import '../state/player_store.dart';
import '../state/settings_store.dart';
import '../theme/aure_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
import 'player_screen.dart';

/// "Personalizar entorno": paisaje, iluminación, colores y sonidos.
class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personalizar'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Guardar'),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Entorno'),
              Tab(text: 'Iluminación'),
              Tab(text: 'Colores'),
              Tab(text: 'Sonidos'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 140,
                child: SceneView(
                  env: s.environment,
                  customImagePath: s.customBackground,
                  brightness: s.illumination,
                  borderRadius: 20,
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _EnvTab(),
                  _LightTab(),
                  _ColorsTab(),
                  AmbientMixer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvTab extends StatelessWidget {
  const _EnvTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final p = context.read<PlayerStore>();
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1,
      children: [
        for (final e in AureEnvironment.all)
          EnvironmentCard(
            env: e,
            selected: s.envId == e.id && s.customBackground == null,
            onTap: () {
              s.selectEnvironment(e);
              p.activeEnvId = e.id;
              p.applyMix(e.defaultMix);
            },
          ),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final img = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (img != null) s.update((s) => s.customBackground = img.path);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: s.customBackground != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: s.customBackground != null ? 2.5 : 1,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined),
                SizedBox(height: 4),
                Text('Tu imagen', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LightTab extends StatelessWidget {
  const _LightTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Iluminación del paisaje'),
        Row(
          children: [
            const Icon(Icons.brightness_low),
            Expanded(
              child: Slider(
                min: 0.3,
                max: 1.3,
                value: s.illumination,
                onChanged: (v) => s.update((s) => s.illumination = v),
              ),
            ),
            const Icon(Icons.brightness_high),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar paisaje en el reproductor'),
          subtitle: const Text('Si lo apagas, se ve la carátula del álbum'),
          value: s.showSceneInPlayer,
          onChanged: (v) => s.update((s) => s.showSceneInPlayer = v),
        ),
      ],
    );
  }
}

class _ColorsTab extends StatelessWidget {
  const _ColorsTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tema'),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode),
              label: Text('Claro'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode),
              label: Text('Oscuro'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto),
              label: Text('Auto'),
            ),
          ],
          selected: {s.themeMode},
          onSelectionChanged: (v) => s.update((s) {
            s.themeMode = v.first;
            s.sunrise = false;
          }),
        ),
        const SizedBox(height: 20),
        const Text('Color principal'),
        const SizedBox(height: 10),
        AccentPicker(
          selected: s.accent,
          onSelected: (c) => s.update((s) => s.accent = c),
        ),
        const SizedBox(height: 20),
        const Text('Tamaño de letra'),
        Slider(
          min: 0.85,
          max: 1.3,
          divisions: 9,
          value: s.fontScale,
          label: '${(s.fontScale * 100).round()}%',
          onChanged: (v) => s.update((s) => s.fontScale = v),
        ),
      ],
    );
  }
}

class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in AurePalette.accents)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected.toARGB32() == c.toARGB32()
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
