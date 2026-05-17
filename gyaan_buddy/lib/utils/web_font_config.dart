import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-specific font configuration to handle font loading issues gracefully
class WebFontConfig {
  static const bool _isWeb = kIsWeb;
  
  /// Check if running on web platform
  static bool get isWeb => _isWeb;
  
  /// Web-safe font fallbacks - using system fonts that work reliably on web
  /// Note: 'Inter' from Google Fonts CSS doesn't work with Flutter's canvas renderer
  /// We use system UI fonts which look modern and work reliably
  static const List<String> webSafeFonts = [
    '-apple-system',      // macOS/iOS system font (San Francisco)
    'BlinkMacSystemFont', // Chrome on macOS
    'Segoe UI',           // Windows
    'Roboto',             // Android/Chrome
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
  
  /// Get web-optimized font family
  static String get webFontFamily {
    if (!isWeb) return 'Inter';
    
    // Return system font stack for reliable web rendering
    return webSafeFonts.join(', ');
  }
  
  /// Get web-optimized text theme
  static TextTheme get webTextTheme {
    if (!isWeb) return Typography.material2021().black;
    
    final fallbackFonts = webSafeFonts.skip(1).toList();
    final primaryFont = webSafeFonts.first;
    
    return Typography.material2021().black.copyWith(
      // Use web-safe fonts with fallback chain
      displayLarge: Typography.material2021().black.displayLarge?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      displayMedium: Typography.material2021().black.displayMedium?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      displaySmall: Typography.material2021().black.displaySmall?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      headlineLarge: Typography.material2021().black.headlineLarge?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      headlineMedium: Typography.material2021().black.headlineMedium?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      headlineSmall: Typography.material2021().black.headlineSmall?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      bodyLarge: Typography.material2021().black.bodyLarge?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      bodyMedium: Typography.material2021().black.bodyMedium?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      bodySmall: Typography.material2021().black.bodySmall?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      titleLarge: Typography.material2021().black.titleLarge?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      titleMedium: Typography.material2021().black.titleMedium?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      titleSmall: Typography.material2021().black.titleSmall?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      labelLarge: Typography.material2021().black.labelLarge?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      labelMedium: Typography.material2021().black.labelMedium?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
      labelSmall: Typography.material2021().black.labelSmall?.copyWith(
        fontFamily: primaryFont,
        fontFamilyFallback: fallbackFonts,
      ),
    );
  }
  
  /// Get web-optimized theme data
  static ThemeData get webThemeData {
    if (!isWeb) return ThemeData.light();
    
          return ThemeData.light().copyWith(
        textTheme: webTextTheme,
        primaryTextTheme: webTextTheme,
      );
  }
  
  /// Check if fonts are available
  static bool get fontsAvailable {
    if (!isWeb) return true;
    
    // In web, we assume fonts are available since we're using web-safe fonts
    return true;
  }
  
  /// Get fallback font for specific text style
  static String getFallbackFont(String? preferredFont) {
    if (!isWeb) return preferredFont ?? 'Inter';
    
    // On web, always use system font stack for reliability
    return webFontFamily;
  }
  
  /// Create web-optimized text style
  static TextStyle createWebTextStyle({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? height,
    double? letterSpacing,
  }) {
    if (!isWeb) {
      return TextStyle(
        fontFamily: fontFamily ?? 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        decoration: decoration,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    
    // On web, use system font stack with fontFamilyFallback
    return TextStyle(
      fontFamily: webSafeFonts.first,
      fontFamilyFallback: webSafeFonts.skip(1).toList(),
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
