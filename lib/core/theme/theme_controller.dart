import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Overridden in `main()` with the already-resolved [SharedPreferences] instance
/// so theme settings can be read synchronously during provider construction.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Curated accent colours offered on the Appearance screen. The first entry is
/// the original brand blue used as the default.
const List<Color> kThemePresets = [
  AppColors.defaultSeed,
  Color(0xFF0F766E),
  Color(0xFF15803D),
  Color(0xFF4D7C0F),
  Color(0xFFB45309),
  Color(0xFFB91C1C),
  Color(0xFF9D174D),
  Color(0xFF6D28D9),
  Color(0xFF4338CA),
  Color(0xFF0369A1),
  Color(0xFF0E7490),
  Color(0xFF374151),
];

/// Persisted appearance preferences: accent colour + light/dark/system mode.
class ThemeSettings {
  final Color seedColor;
  final ThemeMode mode;

  const ThemeSettings({required this.seedColor, required this.mode});

  static const ThemeSettings defaults = ThemeSettings(
    seedColor: AppColors.defaultSeed,
    mode: ThemeMode.light,
  );

  ThemeSettings copyWith({Color? seedColor, ThemeMode? mode}) {
    return ThemeSettings(
      seedColor: seedColor ?? this.seedColor,
      mode: mode ?? this.mode,
    );
  }

  Brightness effectiveBrightness(Brightness platform) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return platform;
    }
  }
}

class ThemeController extends Notifier<ThemeSettings> {
  static const String _seedKey = 'appearance_seed_color';
  static const String _modeKey = 'appearance_theme_mode';

  late SharedPreferences _prefs;

  @override
  ThemeSettings build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return readFrom(_prefs);
  }

  /// Reads persisted settings (used both by the notifier and at startup).
  static ThemeSettings readFrom(SharedPreferences prefs) {
    final seed = prefs.getInt(_seedKey);
    return ThemeSettings(
      seedColor: seed == null ? AppColors.defaultSeed : Color(seed),
      mode: _parseMode(prefs.getString(_modeKey)),
    );
  }

  void setSeedColor(Color color) {
    if (color.toARGB32() == state.seedColor.toARGB32()) return;
    state = state.copyWith(seedColor: color);
    _prefs.setInt(_seedKey, color.toARGB32());
  }

  void setMode(ThemeMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    _prefs.setString(_modeKey, mode.name);
  }

  void resetToDefault() {
    setSeedColor(AppColors.defaultSeed);
    setMode(ThemeMode.light);
  }

  static ThemeMode _parseMode(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeSettings>(
  ThemeController.new,
);

/// Rebuilds its subtree (with a fresh element tree) whenever the appearance
/// settings or the platform brightness change.
///
/// Route pages are cached by the [Navigator], so widgets that read [AppColors]
/// directly would otherwise not refresh when the theme changes. Wrapping each
/// route in this widget guarantees the active screen re-reads the new palette.
class ThemeRebuilder extends ConsumerWidget {
  final WidgetBuilder childBuilder;

  const ThemeRebuilder({super.key, required this.childBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final platform = MediaQuery.platformBrightnessOf(context);
    final key = '${settings.mode.name}-${settings.seedColor.toARGB32()}-$platform';
    return KeyedSubtree(key: ValueKey(key), child: childBuilder(context));
  }
}
