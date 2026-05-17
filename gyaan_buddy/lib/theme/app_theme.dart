import 'package:flutter/material.dart';
import '../utils/web_font_config.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF365DEA);
  static const Color primaryLightColor = Color(0xFF5B7AFF);
  static const Color primaryDarkColor = Color(0xFF2A4BD8);

  // Button Colors
  static const Color buttonColor = Color(0xFF365DEA);
  static const Color buttonTextColor = Colors.white;
  static const Color buttonDisabledColor = Color(0xFFCCCCCC);

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textLightColor = Color(0xFF999999);

  // Background Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);

  // Input Field Colors
  static const Color inputBorderColor = Color(0xFFE0E0E0);
  static const Color inputFillColor = Color(0xFFF5F5F5);
  static const Color inputFocusBorderColor = Color(0xFF365DEA);

  // Error Colors
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF27AE60);
  static const Color warningColor = Color(0xFFF39C12);

  // Theme Data
  static ThemeData get lightTheme {
    // Use web-optimized theme if on web
    if (WebFontConfig.isWeb) {
      return WebFontConfig.webThemeData.copyWith(
        useMaterial3: true,
        
        // Splash/Ripple Effect Configuration
        splashColor: primaryColor.withOpacity(0.15),
        highlightColor: primaryColor.withOpacity(0.08),
        splashFactory: InkSparkle.splashFactory, // Material 3 sparkle effect
        
        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: primaryLightColor,
          surface: surfaceColor,
          background: backgroundColor,
          error: errorColor,
          onPrimary: buttonTextColor,
          onSecondary: buttonTextColor,
          onSurface: textPrimaryColor,
          onBackground: textPrimaryColor,
          onError: buttonTextColor,
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: WebFontConfig.createWebTextStyle(
            color: buttonTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            disabledBackgroundColor: buttonDisabledColor,
            disabledForegroundColor: textLightColor,
            elevation: 2,
            shadowColor: primaryColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            textStyle: WebFontConfig.createWebTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: WebFontConfig.createWebTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputFocusBorderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Progress Indicator Theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryColor,
          linearTrackColor: inputBorderColor,
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: inputBorderColor,
          thickness: 1,
          space: 1,
        ),
      );
    } else {
      // Use regular theme for mobile
      return ThemeData(
        useMaterial3: true,
        
        // Splash/Ripple Effect Configuration
        splashColor: primaryColor.withOpacity(0.15),
        highlightColor: primaryColor.withOpacity(0.08),
        splashFactory: InkSparkle.splashFactory, // Material 3 sparkle effect
        
        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: primaryLightColor,
          surface: surfaceColor,
          background: backgroundColor,
          error: errorColor,
          onPrimary: buttonTextColor,
          onSecondary: buttonTextColor,
          onSurface: textPrimaryColor,
          onBackground: textPrimaryColor,
          onError: buttonTextColor,
        ),

        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            color: buttonTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            disabledBackgroundColor: buttonDisabledColor,
            disabledForegroundColor: textLightColor,
            elevation: 2,
            shadowColor: primaryColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputFocusBorderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Inter',
            color: textSecondaryColor,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Inter',
            color: textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Inter',
            color: textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Inter',
            color: textLightColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Progress Indicator Theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryColor,
          linearTrackColor: inputBorderColor,
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: inputBorderColor,
          thickness: 1,
          space: 1,
        ),
      );
    }
  }

  // Helper method to get button style with custom color
  static ButtonStyle getButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? buttonColor,
      foregroundColor: foregroundColor ?? buttonTextColor,
      elevation: elevation ?? 2,
      shadowColor: (backgroundColor ?? buttonColor).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      textStyle: WebFontConfig.isWeb 
        ? WebFontConfig.createWebTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          )
        : const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
