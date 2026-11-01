import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta base de Aure (tomada de los diseños).
class AurePalette {
  static const violet = Color(0xFF7B5CF6);
  static const purple = Color(0xFFA855F7);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFF47286);
  static const orange = Color(0xFFF97316);
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF60A5FA);
  static const gold = Color(0xFFFFD166);

  static const lightBg = Color(0xFFF6F4FC);
  static const sunriseBg = Color(0xFFFFF3EA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF0E0F1F);
  static const darkSurface = Color(0xFF1A1B30);

  /// Colores que el usuario puede elegir como color principal.
  static const accents = <Color>[
    violet,
    purple,
    pink,
    orange,
    gold,
    green,
    cyan,
    blue,
  ];
}

class AureTheme {
  static ThemeData build({
    required Brightness brightness,
    required Color accent,
    double fontScale = 1.0,
    bool sunrise = false,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      surface: dark ? AurePalette.darkSurface : AurePalette.lightSurface,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: dark
          ? AurePalette.darkBg
          : (sunrise ? AurePalette.sunriseBg : AurePalette.lightBg),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: fontScale),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? AurePalette.darkSurface : AurePalette.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.2),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
