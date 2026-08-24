import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

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
      fontFamily: AppType.bodyFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.compact,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.paper),
      primaryTextTheme: _textTheme(base.primaryTextTheme, AppColors.paper),
      iconTheme: const IconThemeData(color: AppColors.muted, size: 20),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.paper,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.large,
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panelAlt,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        floatingLabelStyle: const TextStyle(
          color: AppColors.teal,
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: const BorderSide(color: AppColors.slate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: AppColors.danger, width: 1.4),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(44),
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.midnight,
          disabledBackgroundColor: AppColors.slate,
          disabledForegroundColor: AppColors.muted,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.medium),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.midnight,
          disabledBackgroundColor: AppColors.slate,
          disabledForegroundColor: AppColors.muted,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.medium),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: AppColors.paper,
          disabledForegroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.slate),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.medium),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          minimumSize:
              const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.slate;
            if (states.contains(WidgetState.pressed)) return AppColors.paper;
            return AppColors.muted;
          }),
          overlayColor: WidgetStatePropertyAll(
            AppColors.teal.withValues(alpha: 0.12),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 62,
        elevation: 0,
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.surfaceHigh,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: AppColors.divider,
        indicatorColor: AppColors.teal,
        labelColor: AppColors.paper,
        unselectedLabelColor: AppColors.muted,
        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(
          color: AppColors.paper,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        actionTextColor: AppColors.amber,
        disabledActionTextColor: AppColors.muted,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.medium,
          side: const BorderSide(color: AppColors.slate),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.navy,
        modalBarrierColor: AppColors.scrim,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.large,
          side: const BorderSide(color: AppColors.slate),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.paper,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          height: 1.4,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        iconColor: AppColors.muted,
        textColor: AppColors.paper,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.content),
        minLeadingWidth: 28,
        minVerticalPadding: AppSpacing.xs,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadii.small,
          border: Border.fromBorderSide(BorderSide(color: AppColors.slate)),
        ),
        textStyle: const TextStyle(
          color: AppColors.paper,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.teal,
        selectionColor: AppColors.slate,
        selectionHandleColor: AppColors.teal,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
        linearTrackColor: AppColors.slate,
        circularTrackColor: AppColors.slate,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.divider, thickness: 1),
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
      fontFamily: AppType.bodyFamily,
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme, AppColors.ink));
  }

  static TextTheme _textTheme(TextTheme base, Color color) {
    return base.apply(bodyColor: color, displayColor: color).copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: AppType.displayFamily,
            fontSize: 42,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: AppType.displayFamily,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: AppType.displayFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.35),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 13, height: 1.35),
          bodySmall: base.bodySmall?.copyWith(fontSize: 11, height: 1.3),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: AppType.dataFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        );
  }
}
