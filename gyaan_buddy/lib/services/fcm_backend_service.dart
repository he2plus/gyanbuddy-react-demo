import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/env.dart';

class FCMBackendService {
  static final FCMBackendService _instance = FCMBackendService._internal();
  factory FCMBackendService() => _instance;
  FCMBackendService._internal();

  final Dio _dio = Dio();
  String? _baseUrl;
  String? _apiKey;

  /// Initialize the service with your backend configuration
  void initialize({required String baseUrl, required String apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;

    // Configure Dio with your backend settings
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // Add interceptors for logging (optional)
    if (kDebugMode && Env.enableNetworkLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
      ));
    }
  }

  /// Send FCM token to your backend server
  Future<bool> sendTokenToServer({
    required String fcmToken,
    required String userId,
    List<String> topics = const [],
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception(
          'FCMBackendService not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/api/fcm/token',
        data: {
          'fcmToken': fcmToken,
          'userId': userId,
          'topics': topics,
          'platform': _getPlatform(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM token sent to backend successfully');
        return true;
      } else {
        debugPrint(
            'Failed to send FCM token to backend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
      return false;
    }
  }

  /// Update user's FCM token
  Future<bool> updateToken({
    required String fcmToken,
    required String userId,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception(
          'FCMBackendService not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.put(
        '/api/fcm/token/$userId',
        data: {
          'fcmToken': fcmToken,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token updated successfully');
        return true;
      } else {
        debugPrint('Failed to update FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
    }
  }

  /// Delete FCM token when user logs out
  Future<bool> deleteToken({
    required String userId,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception(
          'FCMBackendService not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.delete('/api/fcm/token/$userId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('FCM token deleted successfully');
        return true;
      } else {
        debugPrint('Failed to delete FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
      return false;
    }
  }

  /// Subscribe user to topics
  Future<bool> subscribeToTopics({
    required String userId,
    required List<String> topics,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception(
          'FCMBackendService not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/api/fcm/topics/subscribe',
        data: {
          'userId': userId,
          'topics': topics,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Subscribed to topics successfully: $topics');
        return true;
      } else {
        debugPrint('Failed to subscribe to topics: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
      return false;
    }
  }

  /// Unsubscribe user from topics
  Future<bool> unsubscribeFromTopics({
    required String userId,
    required List<String> topics,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception(
          'FCMBackendService not initialized. Call initialize() first.');
    }

    try {
      final response = await _dio.post(
        '/api/fcm/topics/unsubscribe',
        data: {
          'userId': userId,
          'topics': topics,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Unsubscribed from topics successfully: $topics');
        return true;
      } else {
        debugPrint('Failed to unsubscribe from topics: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
      return false;
    }
  }

  /// Get current platform
  String _getPlatform() {
    if (kIsWeb) return 'web';
    // You can add more platform detection logic here
    return 'mobile';
  }

  /// Check if service is initialized
  bool get isInitialized => _baseUrl != null && _apiKey != null;
}
