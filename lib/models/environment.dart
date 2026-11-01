import 'package:flutter/material.dart';

enum SceneKind { forest, beach, mountain, city, space, cabin, aurora, winter }

/// Sonidos ambientales disponibles (archivos en assets/sounds/).
enum AmbientSound {
  rain('Lluvia', Icons.water_drop_outlined, 'rain.wav'),
  wind('Viento', Icons.air, 'wind.wav'),
  birds('Pájaros', Icons.flutter_dash, 'birds.wav'),
  fire('Fogata', Icons.local_fire_department_outlined, 'fire.wav'),
  river('Río', Icons.waves, 'river.wav');

  const AmbientSound(this.label, this.icon, this.file);
  final String label;
  final IconData icon;
  final String file;
  String get asset => 'assets/sounds/$file';
}

/// Un "entorno": paisaje + colores + mezcla de sonidos ambientales.
class AureEnvironment {
  const AureEnvironment({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
    required this.sky,
    required this.ground,
    this.stars = false,
    this.defaultMix = const {},
  });

  final String id;
  final String name;
  final String subtitle;
  final SceneKind kind;
  final List<Color> sky;
  final Color ground;
  final bool stars;
  final Map<AmbientSound, double> defaultMix;

  static const all = <AureEnvironment>[
    AureEnvironment(
      id: 'bosque',
      name: 'Bosque Sereno',
      subtitle: 'Verde, fresco y tranquilo',
      kind: SceneKind.forest,
      sky: [Color(0xFF9CC9D9), Color(0xFFE7D9B8)],
      ground: Color(0xFF1F3B2C),
      defaultMix: {AmbientSound.birds: .5, AmbientSound.river: .3},
    ),
    AureEnvironment(
      id: 'playa',
      name: 'Playa Tropical',
      subtitle: 'Brisa y olas suaves',
      kind: SceneKind.beach,
      sky: [Color(0xFF4FC3F7), Color(0xFFFFE0B2)],
      ground: Color(0xFF0F7C8C),
      defaultMix: {AmbientSound.wind: .3, AmbientSound.river: .5},
    ),
    AureEnvironment(
      id: 'montana',
      name: 'Montaña',
      subtitle: 'Aire limpio y silencio',
      kind: SceneKind.mountain,
      sky: [Color(0xFF6A7FDB), Color(0xFFF2B5D4)],
      ground: Color(0xFF2E2A5A),
      defaultMix: {AmbientSound.wind: .5},
    ),
    AureEnvironment(
      id: 'ciudad',
      name: 'Lluvia en la ciudad',
      subtitle: 'Luces de neón y lluvia',
      kind: SceneKind.city,
      sky: [Color(0xFF1B1D3A), Color(0xFF5B3A7A)],
      ground: Color(0xFF0D0E1F),
      stars: false,
      defaultMix: {AmbientSound.rain: .6},
    ),
    AureEnvironment(
      id: 'espacio',
      name: 'Noche Estrellada',
      subtitle: 'Profundo y calmado',
      kind: SceneKind.space,
      sky: [Color(0xFF0B0B2B), Color(0xFF4A2A8A)],
      ground: Color(0xFF14143A),
      stars: true,
      defaultMix: {AmbientSound.wind: .2},
    ),
    AureEnvironment(
      id: 'cabana',
      name: 'Cabaña',
      subtitle: 'Acogedor y cálido',
      kind: SceneKind.cabin,
      sky: [Color(0xFF1E2A4A), Color(0xFFB0607A)],
      ground: Color(0xFF1A2420),
      stars: true,
      defaultMix: {AmbientSound.fire: .6, AmbientSound.wind: .2},
    ),
    AureEnvironment(
      id: 'aurora',
      name: 'Aurora',
      subtitle: 'Mágico y etéreo',
      kind: SceneKind.aurora,
      sky: [Color(0xFF071A2E), Color(0xFF1E5A6E)],
      ground: Color(0xFF0B1620),
      stars: true,
      defaultMix: {AmbientSound.wind: .4},
    ),
    AureEnvironment(
      id: 'invierno',
      name: 'Invierno',
      subtitle: 'Frío y sereno',
      kind: SceneKind.winter,
      sky: [Color(0xFF9FB6CF), Color(0xFFE8EEF5)],
      ground: Color(0xFFDCE6F0),
      defaultMix: {AmbientSound.wind: .6},
    ),
  ];

  static AureEnvironment byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);
}
