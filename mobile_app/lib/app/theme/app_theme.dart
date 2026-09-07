import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';
import 'app_typography.dart';

/// App theme configurations with Fresh & Modern aesthetic and static caching
class AppTheme {
  AppTheme._();

  static ThemeData? _lightTheme;
  static ThemeData? _darkTheme;

  static ThemeData get lightTheme {
    return _lightTheme ??= _buildLightTheme();
  }

  static ThemeData get darkTheme {
    return _darkTheme ??= _buildDarkTheme();
  }

  static ThemeData _buildLightTheme() {
    final baseTextTheme = AppTypography.textTheme(ColorPalette.lightTextPrimary);

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: ColorPalette.freshEmerald,
        onPrimary: Colors.white,
        primaryContainer: ColorPalette.freshEmeraldLight,
        onPrimaryContainer: ColorPalette.freshEmeraldDark,
        secondary: ColorPalette.electricCyan,
        onSecondary: Colors.white,
        tertiary: ColorPalette.freshEmerald,
        onTertiary: Colors.white,
        surface: ColorPalette.lightCard,
        onSurface: ColorPalette.lightTextPrimary,
        surfaceContainerHighest: ColorPalette.lightSurface,
        error: ColorPalette.sunsetCoral,
        onError: Colors.white,
        outline: ColorPalette.lightBorder,
      ),
      scaffoldBackgroundColor: ColorPalette.lightBg,
      cardTheme: CardThemeData(
        color: ColorPalette.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ColorPalette.lightBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.lightBg,
        foregroundColor: ColorPalette.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.freshEmerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.sunsetCoral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(color: ColorPalette.lightTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.freshEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.freshEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.lightSurface,
        selectedColor: ColorPalette.freshEmeraldLight,
        side: const BorderSide(color: ColorPalette.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
        color: ColorPalette.lightBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: baseTextTheme,
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseTextTheme = AppTypography.textTheme(ColorPalette.darkTextPrimary);

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: ColorPalette.freshEmerald,
        onPrimary: Colors.white,
        primaryContainer: ColorPalette.darkSurfaceHighlight,
        onPrimaryContainer: ColorPalette.freshEmeraldLight,
        secondary: ColorPalette.electricCyan,
        onSecondary: Colors.white,
        tertiary: ColorPalette.freshEmerald,
        onTertiary: ColorPalette.darkBg,
        surface: ColorPalette.darkCard,
        onSurface: ColorPalette.darkTextPrimary,
        surfaceContainerHighest: ColorPalette.darkSurface,
        error: ColorPalette.sunsetCoral,
        onError: Colors.white,
        outline: ColorPalette.darkBorder,
      ),
      scaffoldBackgroundColor: ColorPalette.darkBg,
      cardTheme: CardThemeData(
        color: ColorPalette.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ColorPalette.darkBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.darkBg,
        foregroundColor: ColorPalette.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.freshEmerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ColorPalette.sunsetCoral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(color: ColorPalette.darkTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.freshEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.freshEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorPalette.darkSurface,
        selectedColor: ColorPalette.darkSurfaceHighlight,
        side: const BorderSide(color: ColorPalette.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
        color: ColorPalette.darkBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: baseTextTheme,
    );
  }
}
