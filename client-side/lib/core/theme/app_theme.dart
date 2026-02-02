import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const int defaultAccentColorId = 0;

  static const List<AccentColorOption> accentColorOptions = [
    AccentColorOption(0, Color(0xFF4A6FA5), 'Синий'),
    AccentColorOption(1, Color(0xFF5865F2), 'Discord'),
    AccentColorOption(2, Color(0xFF0088CC), 'Telegram'),
    AccentColorOption(3, Color(0xFF25D366), 'WhatsApp'),
    AccentColorOption(4, Color(0xFF1DB954), 'Spotify'),
    AccentColorOption(5, Color(0xFF2EB886), 'Slack'),
    AccentColorOption(6, Color(0xFF0366D6), 'GitHub'),
  ];

  static Color primaryFromId(int id) {
    if (id < 0 || id >= accentColorOptions.length) {
      return accentColorOptions[defaultAccentColorId].color;
    }
    return accentColorOptions[id].color;
  }

  static Color _primaryDarkFrom(Color primary) {
    return Color.lerp(primary, const Color(0xFF000000), 0.25)!;
  }

  static Color get _primary => accentColorOptions[defaultAccentColorId].color;

  static const Color _darkBg = Color(0xFF252A33);
  static const Color _darkSecondary = Color(0xFF1E2229);
  static const Color _darkTertiary = Color(0xFF181B21);
  static const Color _darkHover = Color(0xFF323842);
  static const Color _darkOnSurface = Color(0xFFD2D6DC);

  static const Color _lightBg = Color(0xFFF2F4F8);
  static const Color _lightSecondary = Color(0xFFFAFBFC);
  static const Color _lightTertiary = Color(0xFFE6E9EF);
  static const Color _lightOnSurface = Color(0xFF2C3E50);

  static ThemeData themeLight([Color? primary]) {
    final p = primary ?? _primary;
    final pDark = _primaryDarkFrom(p);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: p,
        onPrimary: Colors.white,
        primaryContainer: p.withValues(alpha: 0.18),
        onPrimaryContainer: pDark,
        surface: _lightSecondary,
        onSurface: _lightOnSurface,
        surfaceContainerHighest: _lightTertiary,
        outline: const Color(0xFF7B8FA3),
        outlineVariant: const Color(0xFFD0D6DE),
      ),
      scaffoldBackgroundColor: _lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSecondary,
        foregroundColor: _lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: _lightSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: _lightTertiary,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          maximumSize: const Size(48, 48),
          iconSize: 26,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData get light => themeLight(null);

  static ThemeData themeDark([Color? primary]) {
    final p = primary ?? _primary;
    final pDark = _primaryDarkFrom(p);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: p,
        onPrimary: Colors.white,
        primaryContainer: pDark,
        onPrimaryContainer: _darkOnSurface,
        surface: _darkBg,
        onSurface: _darkOnSurface,
        surfaceContainerHighest: _darkHover,
        outline: const Color(0xFF6B7D8F),
        outlineVariant: const Color(0xFF454D58),
      ),
      scaffoldBackgroundColor: _darkTertiary,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _darkSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: _darkHover,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          maximumSize: const Size(48, 48),
          iconSize: 26,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark => themeDark(null);

  static Color railBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkTertiary
        : const Color(0xFFE8ECF2);
  }

  static Color channelsBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkSecondary
        : _lightSecondary;
  }
}

class AccentColorOption {
  final int id;
  final Color color;
  final String label;

  const AccentColorOption(this.id, this.color, this.label);
}
