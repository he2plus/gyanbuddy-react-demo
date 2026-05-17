import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:flutter/foundation.dart';

class PostHogService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    try {
      // PostHog is configured through platform-specific files
      // Android: AndroidManifest.xml
      // iOS: Info.plist  
      // Web: index.html
      // No setup method needed in Flutter code
      
      // Wait a bit for platform channels to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Set initial context (not supported on web)
      if (!kIsWeb) {
        await Posthog().setContext({
          'app_name': 'GyanBuddy',
          'platform': 'flutter',
          'version': '1.0.0',
        });
      }
      
      _isInitialized = true;
      if (kDebugMode) {
        print('PostHog initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PostHog initialization failed: $e');
      }
      // Don't throw error, just mark as not initialized
      _isInitialized = false;
    }
  }
  
  static bool get isInitialized => _isInitialized;
  
  static void identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) {
    if (!_isInitialized) return;
    try {
      Posthog().identify(
        userId: userId,
        properties: userProperties,
      );
    } catch (e) {
      if (kDebugMode) {
        print('PostHog identify failed: $e');
      }
    }
  }
  
  static void capture(
    String eventName, {
    Map<String, dynamic>? properties,
  }) {
    if (!_isInitialized) return;
    try {
      Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (e) {
      if (kDebugMode) {
        print('PostHog capture failed: $e');
      }
    }
  }
  
  static void setContext(Map<String, dynamic> context) {
    if (!_isInitialized) return;
    // setContext is not supported on web
    if (kIsWeb) return;
    try {
      Posthog().setContext(context);
    } catch (e) {
      if (kDebugMode) {
        print('PostHog setContext failed: $e');
      }
    }
  }
  
  static void reset() {
    if (!_isInitialized) return;
    try {
      Posthog().reset();
    } catch (e) {
      if (kDebugMode) {
        print('PostHog reset failed: $e');
      }
    }
  }
  
  static void screen(String screenName, {Map<String, dynamic>? properties}) {
    if (!_isInitialized) return;
    try {
      Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (e) {
      if (kDebugMode) {
        print('PostHog screen failed: $e');
      }
    }
  }
  
  static void group(String groupType, String groupKey, {Map<String, dynamic>? groupProperties}) {
    if (!_isInitialized) return;
    try {
      Posthog().group(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: groupProperties ?? {},
      );
    } catch (e) {
      if (kDebugMode) {
        print('PostHog group failed: $e');
      }
    }
  }
  
  static Future<bool?> isFeatureEnabled(String flagKey) async {
    if (!_isInitialized) return null;
    try {
      return await Posthog().isFeatureEnabled(flagKey);
    } catch (e) {
      if (kDebugMode) {
        print('PostHog isFeatureEnabled failed: $e');
      }
      return null;
    }
  }
  
  static void reloadFeatureFlags() {
    if (!_isInitialized) return;
    try {
      Posthog().reloadFeatureFlags();
    } catch (e) {
      if (kDebugMode) {
        print('PostHog reloadFeatureFlags failed: $e');
      }
    }
  }
  
  static void alias(String alias) {
    if (!_isInitialized) return;
    try {
      Posthog().alias(alias: alias);
    } catch (e) {
      if (kDebugMode) {
        print('PostHog alias failed: $e');
      }
    }
  }
  
  static void enable() {
    if (!_isInitialized) return;
    try {
      Posthog().enable();
    } catch (e) {
      if (kDebugMode) {
        print('PostHog enable failed: $e');
      }
    }
  }
  
  static void disable() {
    if (!_isInitialized) return;
    try {
      Posthog().disable();
    } catch (e) {
      if (kDebugMode) {
        print('PostHog disable failed: $e');
      }
    }
  }
  
  static Future<String?> getAnonymousId() async {
    if (!_isInitialized) return null;
    try {
      return await Posthog().getAnonymousId;
    } catch (e) {
      if (kDebugMode) {
        print('PostHog getAnonymousId failed: $e');
      }
      return null;
    }
  }
}
