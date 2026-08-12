import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache_service.dart';

class AppTheme {
  AppTheme._();

  // Primary: Crimson/Emergency Signal Red
  static const Color primaryColor = Color(0xFFBD0022); 
  // Secondary: Safety Deep Navy Blue
  static const Color secondaryColor = Color(0xFF4C56AF); 
  // Accent/Alert: Amber Orange / Tertiary
  static const Color warningColor = Color(0xFF895000); 

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      scaffoldBackground: const Color(0xFFF9F9FB),
      surface: const Color(0xFFF9F9FB),
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8, // 0.5rem (8px) as per DESIGN.md
        cardRadius: 16, // 1rem (16px) as per DESIGN.md
        buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily, // Plus Jakarta Sans as per DESIGN.md
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      primaryLightRef: primaryColor,
      secondaryLightRef: secondaryColor,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8, // 0.5rem (8px) as per DESIGN.md
        cardRadius: 16, // 1rem (16px) as per DESIGN.md
        buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily, // Plus Jakarta Sans as per DESIGN.md
    );
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const String _key = 'user_theme_mode';

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    final storedVal = _prefs.getString(_key);
    if (storedVal != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == storedVal,
        orElse: () => ThemeMode.system,
      );
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(_key, mode.toString());
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
