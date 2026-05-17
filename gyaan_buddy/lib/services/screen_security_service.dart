import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Service to prevent screenshots and screen recordings on sensitive screens.
/// Uses FLAG_SECURE on Android to block screenshots and screen recordings.
/// iOS allows detection but not full blocking of screen recording.
class ScreenSecurityService {
  static final ScreenSecurityService _instance = ScreenSecurityService._internal();
  final NoScreenshot _noScreenshot = NoScreenshot.instance;
  
  factory ScreenSecurityService() => _instance;
  
  ScreenSecurityService._internal();

  /// Enable screen security (prevent screenshots and recordings)
  /// Call this in initState of screens that need protection
  Future<void> enableSecureMode() async {
    // Skip on web platform
    if (kIsWeb) return;
    
    try {
      await _noScreenshot.screenshotOff();
      debugPrint('🔒 ScreenSecurityService: Secure mode enabled');
    } catch (e) {
      debugPrint('⚠️ ScreenSecurityService: Error enabling secure mode: $e');
    }
  }

  /// Disable screen security (allow screenshots and recordings)
  /// Call this in dispose of screens that had protection enabled
  Future<void> disableSecureMode() async {
    // Skip on web platform
    if (kIsWeb) return;
    
    try {
      await _noScreenshot.screenshotOn();
      debugPrint('🔓 ScreenSecurityService: Secure mode disabled');
    } catch (e) {
      debugPrint('⚠️ ScreenSecurityService: Error disabling secure mode: $e');
    }
  }
}
