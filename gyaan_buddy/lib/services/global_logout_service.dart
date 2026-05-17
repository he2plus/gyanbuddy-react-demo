import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../services/token_storage_service.dart';
import '../services/user_api_service.dart';

/// Global service to handle automatic logout when tokens expire or unauthorized errors occur
class GlobalLogoutService {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static bool _isLoggingOut = false;
  
  /// Set the navigator key for navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey.currentState != null;
  }
  
  /// Perform automatic logout
  static Future<void> logout() async {
    if (_isLoggingOut) return; // Prevent multiple simultaneous logouts
    
    _isLoggingOut = true;
    
    try {
      // Clear tokens from storage
      await TokenStorageService.clearTokens();
      
      // Clear auth token from API service
      final userApiService = UserApiService();
      userApiService.clearAuthToken();
      
      // Navigate to login screen if navigator is available
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      
      // Show a brief message to user (optional)
      if (_navigatorKey.currentState != null) {
        ScaffoldMessenger.of(_navigatorKey.currentState!.context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      print('Error during global logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }
  
  /// Check if currently logging out
  static bool get isLoggingOut => _isLoggingOut;
  
  /// Get the navigator key
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
