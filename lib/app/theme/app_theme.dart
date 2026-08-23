import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.teal,
      onPrimary: AppColors.midnight,
      secondary: AppColors.amber,
      onSecondary: AppColors.midnight,
      surface: AppColors.navy,
      onSurface: AppColors.paper,
      error: AppColors.danger,
      onError: AppColors.midnight,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.midnight,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.paper),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.navy,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.slate),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.navy,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.midnight,
          disabledBackgroundColor: AppColors.slate,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: AppColors.paper,
          disabledForegroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.slate),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 62,
        elevation: 0,
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.slate,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.slate, thickness: 1),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: Brightness.light,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.paper,
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme, AppColors.ink));
  }

  static TextTheme _textTheme(TextTheme base, Color color) {
    return base.apply(bodyColor: color, displayColor: color).copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: 'sans-serif-condensed',
            fontSize: 48,
            height: 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: 'sans-serif-condensed',
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: 'sans-serif-condensed',
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        );
  }
}
