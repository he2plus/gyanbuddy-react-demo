import 'package:flutter/foundation.dart';

/// Web-specific configuration for handling connectivity and CORS issues
class WebConfig {
  static const bool _isWeb = kIsWeb;
  
  /// Check if running on web platform
  static bool get isWeb => _isWeb;
  
  /// Web-specific API configuration
  static const Map<String, dynamic> webApiConfig = {
    'corsEnabled': true,
    'credentials': 'include',
    'mode': 'cors',
    'headers': {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
    },
  };
  
  /// Web-specific timeout values (shorter for web)
  static const Map<String, int> webTimeouts = {
    'connectTimeout': 15, // 15 seconds for web
    'receiveTimeout': 20, // 20 seconds for web
    'sendTimeout': 15,    // 15 seconds for web
  };
  
  /// Web-specific retry configuration
  static const Map<String, dynamic> webRetryConfig = {
    'maxRetries': 3,
    'retryDelay': 1000, // 1 second
    'backoffMultiplier': 2.0,
  };
  
  /// Web-specific error messages
  static const Map<String, String> webErrorMessages = {
    'noConnection': 'No internet connection detected. Please check your network settings.',
    'corsError': 'Cross-origin request blocked. This might be a server configuration issue.',
    'timeout': 'Request timed out. Please try again.',
    'serverError': 'Server error. Please try again later.',
    'unknown': 'An unknown error occurred. Please try refreshing the page.',
  };
  
  /// Get appropriate timeout for web vs mobile
  static int getTimeout(String timeoutType, int mobileValue) {
    if (!isWeb) return mobileValue;
    
    switch (timeoutType) {
      case 'connect':
        return webTimeouts['connectTimeout'] ?? mobileValue;
      case 'receive':
        return webTimeouts['receiveTimeout'] ?? mobileValue;
      case 'send':
        return webTimeouts['sendTimeout'] ?? mobileValue;
      default:
        return mobileValue;
    }
  }
  
  /// Get web-specific error message
  static String getErrorMessage(String errorType) {
    if (!isWeb) return 'Network error occurred';
    
    return webErrorMessages[errorType] ?? webErrorMessages['unknown']!;
  }
  
  /// Check if CORS should be enabled
  static bool get shouldEnableCors => isWeb && webApiConfig['corsEnabled'] == true;
  
  /// Get web-specific headers
  static Map<String, String> get webHeaders {
    if (!isWeb) return {};
    
    final headers = <String, String>{};
    final configHeaders = webApiConfig['headers'] as Map<String, dynamic>;
    
    configHeaders.forEach((key, value) {
      if (value is String) {
        headers[key] = value;
      }
    });
    
    return headers;
  }
}
