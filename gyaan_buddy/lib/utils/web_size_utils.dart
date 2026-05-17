import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Web-aware sizing utilities for landscape-oriented web screens.
/// 
/// On web (landscape), height is the constraining dimension.
/// On mobile (portrait), width is the constraining dimension.
/// 
/// These utilities scale values appropriately for each platform.

/// Global scale factor for web - based on viewport height
/// Reference height is 932 (iPhone design height)
double _webScale(BuildContext? context) {
  if (context == null) return 1.0;
  final height = MediaQuery.of(context).size.height;
  return (height / 932).clamp(0.5, 1.5);
}

/// Extension for web-aware sizing
extension WebSizeExtension on num {
  /// Web-aware font size - scales based on viewport on web
  double get spWeb {
    if (kIsWeb) return toDouble();
    return sp;
  }

  /// Web-aware width - returns raw value on web
  double get wWeb {
    if (kIsWeb) return toDouble();
    return w;
  }

  /// Web-aware height - returns raw value on web
  double get hWeb {
    if (kIsWeb) return toDouble();
    return h;
  }

  /// Web-aware radius - returns raw value on web
  double get rWeb {
    if (kIsWeb) return toDouble();
    return r;
  }
  
  /// Screen width percentage
  double get swWeb => sw;
  
  /// Screen height percentage
  double get shWeb => sh;
}

/// Context-aware sizing that scales properly on web based on viewport
extension WebContextSizing on num {
  /// Get scaled size for web (scales based on viewport height)
  double webScaled(BuildContext context) {
    if (!kIsWeb) return w;
    final scale = _webScale(context);
    return toDouble() * scale;
  }
  
  /// Get scaled height for web
  double webScaledH(BuildContext context) {
    if (!kIsWeb) return h;
    final scale = _webScale(context);
    return toDouble() * scale;
  }
  
  /// Get scaled font size for web
  double webScaledSp(BuildContext context) {
    if (!kIsWeb) return sp;
    final scale = _webScale(context);
    return toDouble() * scale;
  }
  
  /// Get scaled radius for web
  double webScaledR(BuildContext context) {
    if (!kIsWeb) return r;
    final scale = _webScale(context);
    return toDouble() * scale;
  }
}

/// Helper class for responsive sizing with static methods
class WebSize {
  static bool get isWeb => kIsWeb;
  
  /// Get scale factor based on viewport height
  static double getScale(BuildContext context) {
    if (!kIsWeb) return 1.0;
    return _webScale(context);
  }
  
  /// Scale a value for web based on viewport
  static double scale(BuildContext context, double value) {
    if (!kIsWeb) return value;
    return value * _webScale(context);
  }
  
  /// Get font size scaled for both platforms
  static double fontSize(BuildContext context, double baseSize) {
    if (kIsWeb) return baseSize * _webScale(context);
    return baseSize.sp;
  }

  /// Get width scaled for both platforms
  static double width(BuildContext context, double baseSize) {
    if (kIsWeb) return baseSize * _webScale(context);
    return baseSize.w;
  }

  /// Get height scaled for both platforms
  static double height(BuildContext context, double baseSize) {
    if (kIsWeb) return baseSize * _webScale(context);
    return baseSize.h;
  }
  
  /// Get radius scaled for both platforms
  static double radius(BuildContext context, double baseSize) {
    if (kIsWeb) return baseSize * _webScale(context);
    return baseSize.r;
  }
  
  /// Get responsive value
  static double responsive(double webValue, double mobileValue) {
    return kIsWeb ? webValue : mobileValue;
  }
  
  /// Get value scaled by screen height percentage (useful for both platforms)
  static double byScreenHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }
  
  /// Get value scaled by screen width percentage
  static double byScreenWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
}

