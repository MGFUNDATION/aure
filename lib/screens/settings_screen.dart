import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/settings_store.dart';
import '../theme/aure_theme.dart';

/// Ajustes (se abre con el engrane del Perfil), según el diseño.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final lib = context.read<LibraryStore>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6);

    final current = s.sunrise
        ? 'sunrise'
        : switch (s.themeMode) {
            ThemeMode.light => 'light',
            ThemeMode.dark => 'dark',
            ThemeMode.system => dark ? 'dark' : 'light',
          };

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF1A1C33), Color(0xFF0E0F1F)]
                : s.sunrise
                ? const [Color(0xFFFFF0E4), Color(0xFFFDE7EF)]
                : const [Color(0xFFF7F5FD), Color(0xFFEDF1F9)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(LucideIcons.chevronLeft),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Text(
                    'Ajustes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Label('Apariencia'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ThemeTile(
                    icon: LucideIcons.sun,
                    label: 'Claro',
                    selected: current == 'light',
                    onTap: () => s.update((s) {
                      s.themeMode = ThemeMode.light;
                      s.sunrise = false;
                    }),
                  ),
                  const SizedBox(width: 10),
                  _ThemeTile(
                    icon: LucideIcons.moon,
                    label: 'Oscuro',
                    selected: current == 'dark',
                    onTap: () => s.update((s) {
                      s.themeMode = ThemeMode.dark;
                      s.sunrise = false;
                    }),
                  ),
                  const SizedBox(width: 10),
                  _ThemeTile(
                    icon: LucideIcons.sunrise,
                    label: 'Amanecer',
                    selected: current == 'sunrise',
                    onTap: () => s.update((s) => s.sunrise = true),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _Label('Color principal'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final c in AurePalette.accents)
                    GestureDetector(
                      onTap: () => s.update((s) => s.accent = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            width: 2.5,
                            color: s.accent.toARGB32() == c.toARGB32()
                                ? (dark ? Colors.white : Colors.black87)
                                : Colors.transparent,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _Divider(),
              _Item(
                title: 'Idioma',
                value: s.language,
                muted: muted,
                onTap: () => _pick(
                  context,
                  'Idioma',
                  ['Español'],
                  s.language,
                  (v) => s.update((s) => s.language = v),
                  footer: 'Más idiomas muy pronto.',
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Sincronización en la nube',
                value: s.cloudSync ? 'Activada' : 'Próximamente',
                muted: muted,
                trailing: Switch(
                  value: s.cloudSync,
                  activeTrackColor: AurePalette.green,
                  onChanged: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La sincronización entre dispositivos llegará en una próxima versión. Por ahora todo se guarda en tu teléfono.',
                      ),
                    ),
                  ),
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Descargar contenidos',
                value: s.wifiOnlyDownloads
                    ? 'Solo con Wi-Fi'
                    : 'Wi-Fi y datos móviles',
                muted: muted,
                onTap: () => _pick(
                  context,
                  'Descargar contenidos',
                  ['Solo con Wi-Fi', 'Wi-Fi y datos móviles'],
                  s.wifiOnlyDownloads
                      ? 'Solo con Wi-Fi'
                      : 'Wi-Fi y datos móviles',
                  (v) => s.update(
                    (s) => s.wifiOnlyDownloads = v == 'Solo con Wi-Fi',
                  ),
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Calidad de audio',
                value: s.downloadQuality.label,
                muted: muted,
                onTap: () => _pick(
                  context,
                  'Calidad de audio',
                  [for (final q in DownloadQuality.values) q.label],
                  s.downloadQuality.label,
                  (v) => s.update(
                    (s) => s.downloadQuality = DownloadQuality.values
                        .firstWhere((q) => q.label == v),
                  ),
                  footer: 'Se usa al descargar música libre desde Aure IA.',
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Letras automáticas',
                value: s.autoLyrics ? 'Activadas' : 'Desactivadas',
                muted: muted,
                trailing: Switch(
                  value: s.autoLyrics,
                  activeTrackColor: AurePalette.green,
                  onChanged: (v) => s.update((s) => s.autoLyrics = v),
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Funciones en línea',
                value: s.onlineFeatures
                    ? 'Letras, reconocimiento y música libre'
                    : 'Aure funciona 100% sin internet',
                muted: muted,
                trailing: Switch(
                  value: s.onlineFeatures,
                  activeTrackColor: AurePalette.green,
                  onChanged: (v) => s.update((s) => s.onlineFeatures = v),
                ),
              ),
              const _Divider(),
              _Item(
                title: 'Buscar música en el teléfono',
                value: 'Volver a leer tus canciones',
                muted: muted,
                onTap: lib.scan,
              ),
              const _Divider(),
              _Item(
                title: 'Acerca de Aure',
                value: 'Versión 0.1.0',
                muted: muted,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Aure',
                  applicationVersion: '0.1.0',
                  children: const [
                    Text(
                      'Tu música. Tu mundo. Tu momento.\n\n'
                      'Tus datos se quedan en tu teléfono. Solo verás un anuncio corto, '
                      'si tú lo eliges, al descargar una canción libre gratis.',
                    ),
                  ],
                ),
                showChevron: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onPick, {
    String? footer,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: o == current
                    ? Icon(
                        LucideIcons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  onPick(o);
                  Navigator.pop(ctx);
                },
              ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Text(footer, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
  );
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : (dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.8)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? accent
                      : (dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE6E2F2)),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Icon(icon, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.title,
    required this.value,
    required this.muted,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });
  final String title;
  final String value;
  final Color? muted;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ),
          ?trailing ??
              (showChevron
                  ? const Icon(LucideIcons.chevronRight, size: 18)
                  : null),
        ],
      ),
    ),
  );
}
