import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lightens/darkens a colour by [amount] (positive = lighter, negative = darker).
Color _shift(Color base, double amount) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// Semantic colour palette for a single [Brightness].
///
/// The app UI reads colours through [AppColors], which always points to the
/// palette of the currently active theme. That keeps every existing
/// `AppColors.xxx` call site working while still allowing the palette to be
/// swapped at runtime (theme colour + light/dark).
class AppPalette {
  final Brightness brightness;

  /// User-selectable accent colour.
  final Color primary;
  final Color primaryDark;
  final Color accent;

  final Color surface;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color danger;
  final Color success;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.danger,
    required this.success,
  });

  static AppPalette light(Color seed) {
    return AppPalette(
      brightness: Brightness.light,
      primary: seed,
      primaryDark: Color.lerp(seed, Colors.black, 0.15)!,
      accent: _shift(seed, 0.10),
      surface: const Color(0xFFF7F9FC),
      card: const Color(0xFFFFFFFF),
      text: const Color(0xFF1C2833),
      muted: const Color(0xFF5D6D7E),
      border: const Color(0xFFD5D8DC),
      danger: const Color(0xFFC0392B),
      success: const Color(0xFF1E8449),
    );
  }

  static AppPalette dark(Color seed) {
    return AppPalette(
      brightness: Brightness.dark,
      primary: _shift(seed, 0.16),
      primaryDark: Color.lerp(seed, Colors.black, 0.15)!,
      accent: _shift(seed, 0.26),
      surface: const Color(0xFF0E1216),
      card: const Color(0xFF1A2027),
      text: const Color(0xFFE8ECEF),
      muted: const Color(0xFF9AA5B1),
      border: const Color(0xFF2A323A),
      danger: const Color(0xFFEF5350),
      success: const Color(0xFF4CAF50),
    );
  }

  static AppPalette forBrightness(Brightness brightness, Color seed) =>
      brightness == Brightness.dark ? dark(seed) : light(seed);
}

/// Global accessor for the active palette.
///
/// Kept as static getters (instead of const fields) so the whole app can be
/// re-themed at runtime without touching the ~1300 existing call sites.
class AppColors {
  AppColors._();

  /// Original brand colour — the default theme colour.
  static const Color defaultSeed = Color(0xFF1B4F72);

  static AppPalette _palette = AppPalette.light(defaultSeed);

  static AppPalette get palette => _palette;

  static void apply(AppPalette palette) => _palette = palette;

  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get accent => _palette.accent;
  static Color get surface => _palette.surface;
  static Color get card => _palette.card;
  static Color get text => _palette.text;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static Color get danger => _palette.danger;
  static Color get success => _palette.success;
}

class AppTheme {
  static ThemeData light(Color seed) => _build(AppPalette.light(seed), seed);

  static ThemeData dark(Color seed) => _build(AppPalette.dark(seed), seed);

  static ThemeData _build(AppPalette p, Color seed) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: p.brightness,
        primary: p.primary,
        surface: p.surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      dividerColor: p.border,
      iconTheme: IconThemeData(color: p.text),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.card,
        foregroundColor: p.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
    );
  }
}
