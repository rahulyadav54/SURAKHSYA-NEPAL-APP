import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Primary: Crimson/Emergency Red (reflective of Nepal's national colors)
  static const Color primaryColor = Color(0xFFD71920); 
  // Secondary: Safety Deep Navy Blue
  static const Color secondaryColor = Color(0xFF1C2A38); 
  // Accent/Alert: Amber Orange
  static const Color warningColor = Color(0xFFFF8C00); 

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12,
        cardRadius: 16,
        buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
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
        inputDecoratorRadius: 12,
        cardRadius: 16,
        buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
    );
  }
}
