import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/environment.dart';
import '../theme/aure_theme.dart';

enum DownloadQuality {
  low('Baja', '≈96 kbps · ahorra espacio'),
  medium('Media', '≈192 kbps · equilibrio'),
  high('Alta', 'Máxima disponible (FLAC si existe)');

  const DownloadQuality(this.label, this.detail);
  final String label;
  final String detail;
}

/// Todo lo que el usuario puede personalizar. Se guarda en el dispositivo.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  ThemeMode themeMode = ThemeMode.system;
  bool sunrise = false; // tema "Amanecer"
  bool cloudSync = false;
  bool wifiOnlyDownloads = true;
  String language = 'Español';
  Color accent = AurePalette.violet;
  String envId = AureEnvironment.all.first.id;
  String? customBackground; // ruta de imagen propia
  double illumination = 1.0;
  double fontScale = 1.0;
  bool showSceneInPlayer = true;
  bool autoLyrics = true;
  bool onlineFeatures = true; // letras / reconocimiento (requiere internet)
  DownloadQuality downloadQuality = DownloadQuality.medium;
  Map<AmbientSound, double> ambientMix = {};
  String userName = 'Valeria';
  String userHandle = '@aure';
  String bio = 'Vivo en mi mundo y la música es lo que lo hace real.';
  String? avatarPath;
  String? profileCoverPath;

  /// Tema visible: claro, oscuro o amanecer (claro cálido).
  ThemeMode get effectiveThemeMode => sunrise ? ThemeMode.light : themeMode;

  AureEnvironment get environment => AureEnvironment.byId(envId);

  void _load() {
    themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    sunrise = _prefs.getBool('sunrise') ?? false;
    cloudSync = _prefs.getBool('cloudSync') ?? false;
    wifiOnlyDownloads = _prefs.getBool('wifiOnlyDownloads') ?? true;
    language = _prefs.getString('language') ?? language;
    accent = Color(_prefs.getInt('accent') ?? AurePalette.violet.toARGB32());
    envId = _prefs.getString('envId') ?? envId;
    customBackground = _prefs.getString('customBackground');
    illumination = _prefs.getDouble('illumination') ?? 1.0;
    fontScale = _prefs.getDouble('fontScale') ?? 1.0;
    showSceneInPlayer = _prefs.getBool('showSceneInPlayer') ?? true;
    autoLyrics = _prefs.getBool('autoLyrics') ?? true;
    onlineFeatures = _prefs.getBool('onlineFeatures') ?? true;
    downloadQuality =
        DownloadQuality.values[_prefs.getInt('downloadQuality') ?? 1];
    userName = _prefs.getString('userName') ?? userName;
    userHandle = _prefs.getString('userHandle') ?? userHandle;
    bio = _prefs.getString('bio') ?? bio;
    avatarPath = _prefs.getString('avatarPath');
    profileCoverPath = _prefs.getString('profileCoverPath');
    final mix = _prefs.getString('ambientMix');
    if (mix != null) {
      final m = jsonDecode(mix) as Map<String, dynamic>;
      ambientMix = {
        for (final e in m.entries)
          AmbientSound.values.byName(e.key): (e.value as num).toDouble(),
      };
    }
  }

  Future<void> _save() async {
    await _prefs.setInt('themeMode', themeMode.index);
    await _prefs.setBool('sunrise', sunrise);
    await _prefs.setBool('cloudSync', cloudSync);
    await _prefs.setBool('wifiOnlyDownloads', wifiOnlyDownloads);
    await _prefs.setString('language', language);
    await _prefs.setInt('accent', accent.toARGB32());
    await _prefs.setString('envId', envId);
    if (customBackground == null) {
      await _prefs.remove('customBackground');
    } else {
      await _prefs.setString('customBackground', customBackground!);
    }
    await _prefs.setDouble('illumination', illumination);
    await _prefs.setDouble('fontScale', fontScale);
    await _prefs.setBool('showSceneInPlayer', showSceneInPlayer);
    await _prefs.setBool('autoLyrics', autoLyrics);
    await _prefs.setBool('onlineFeatures', onlineFeatures);
    await _prefs.setInt('downloadQuality', downloadQuality.index);
    await _prefs.setString('userName', userName);
    await _prefs.setString('userHandle', userHandle);
    await _prefs.setString('bio', bio);
    if (avatarPath != null) await _prefs.setString('avatarPath', avatarPath!);
    if (profileCoverPath != null) {
      await _prefs.setString('profileCoverPath', profileCoverPath!);
    }
    await _prefs.setString(
      'ambientMix',
      jsonEncode({for (final e in ambientMix.entries) e.key.name: e.value}),
    );
  }

  void update(void Function(SettingsStore s) change) {
    change(this);
    notifyListeners();
    _save();
  }

  void selectEnvironment(AureEnvironment env, {bool applyMix = true}) {
    update((s) {
      s.envId = env.id;
      s.customBackground = null;
      if (applyMix) s.ambientMix = Map.of(env.defaultMix);
    });
  }
}
