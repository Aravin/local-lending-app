import 'package:flutter/material.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

/// Builds the Material 3 ThemeData from the active flavor's AppConfig.
/// Call ThemeBuilder.build() in MaterialApp.theme.
class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final primaryColor = FlavorConfig.primaryColor;
    final secondaryColor = FlavorConfig.secondaryColor;
    final tertiaryColor = FlavorConfig.tertiaryColor;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary — Deep Teal
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor.withAlpha(204), // 80% opacity
      onPrimaryContainer: const Color(0xFFF4FFFC),
      // Secondary — Soft Green
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF6BFF8F),
      onSecondaryContainer: const Color(0xFF007432),
      // Tertiary — Deep Blue
      tertiary: tertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF506CDB),
      onTertiaryContainer: Colors.white,
      // Surface
      surface: const Color(0xFFF8F9FF),
      onSurface: const Color(0xFF0B1C30),
      surfaceContainerHighest: const Color(0xFFD3E4FE),
      surfaceContainerHigh: const Color(0xFFDCE9FF),
      surfaceContainer: const Color(0xFFE5EEFF),
      surfaceContainerLow: const Color(0xFFEFF4FF),
      surfaceContainerLowest: Colors.white,
      surfaceDim: const Color(0xFFCBDBF5),
      surfaceBright: const Color(0xFFF8F9FF),
      // Inverse
      inverseSurface: const Color(0xFF213145),
      onInverseSurface: const Color(0xFFEAF1FF),
      inversePrimary: const Color(0xFF6BD8CB),
      // Neutral
      outline: const Color(0xFF6D7A77),
      outlineVariant: const Color(0xFFBCC9C6),
      // Error
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      // Scrim / shadow
      scrim: Colors.black,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      textTheme: AppTypography.textTheme,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Elevated Button — Primary CTA
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // 1.5rem — "touchable"
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      // Outlined Button — Secondary CTA
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withAlpha(153),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: primaryColor.withAlpha(13), // 5% teal shadow
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withAlpha(26), // 10%
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Chip / Badge
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999), // pill
        ),
        labelStyle: AppTypography.textTheme.labelSmall,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFBCC9C6),
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF213145),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Typography scale from the Kinship Lending System design spec.
class AppTypography {
  AppTypography._();

  static const TextTheme textTheme = TextTheme(
    // display-lg: 32px / 700 / -0.02em
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.64, // -0.02em × 32px
      height: 1.25, // 40/32
    ),
    // headline-lg: 24px / 600 / -0.01em
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
      height: 1.33, // 32/24
    ),
    // headline-md: 20px / 600
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4, // 28/20
    ),
    // headline-lg-mobile: 22px / 600
    headlineSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27, // 28/22
    ),
    // title-lg: used for app bar titles
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    // body-lg: 16px / 400
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5, // 24/16
    ),
    // body-md: 14px / 400
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43, // 20/14
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    // label-md: 12px / 500 / 0.05em
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6, // 0.05em × 12px
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}
