import 'package:flutter/foundation.dart';

/// Centralized logging utility to replace scattered print statements
/// Provides consistent logging across the application
class AppLogger {
  
  // ==================== LOG LEVELS ====================
  
  static const String _debugPrefix = '🐛 DEBUG';
  static const String _infoPrefix = 'ℹ️ INFO';
  static const String _warningPrefix = '⚠️ WARNING';
  static const String _errorPrefix = '❌ ERROR';
  static const String _successPrefix = '✅ SUCCESS';
  static const String _apiPrefix = '🔵 API';
  static const String _blocPrefix = '🔄 BLOC';
  static const String _uiPrefix = '🎨 UI';
  static const String _navPrefix = '🧭 NAV';
  static const String _authPrefix = '🔐 AUTH';
  static const String _dataPrefix = '💾 DATA';

  // ==================== CORE LOGGING METHODS ====================

  /// Debug level logging
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_debugPrefix, message, tag);
    }
  }

  /// Info level logging
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_infoPrefix, message, tag);
    }
  }

  /// Warning level logging
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_warningPrefix, message, tag);
    }
  }

  /// Error level logging
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log(_errorPrefix, message, tag);
      if (error != null) {
        _log(_errorPrefix, 'Error details: $error', tag);
      }
      if (stackTrace != null) {
        _log(_errorPrefix, 'Stack trace: $stackTrace', tag);
      }
    }
  }

  /// Success level logging
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_successPrefix, message, tag);
    }
  }

  // ==================== CATEGORY-SPECIFIC LOGGING ====================

  /// API-related logging
  static void api(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_apiPrefix, message, tag);
    }
  }

  /// BLoC state logging
  static void bloc(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_blocPrefix, message, tag);
    }
  }

  /// UI-related logging
  static void ui(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_uiPrefix, message, tag);
    }
  }

  /// Navigation logging
  static void nav(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_navPrefix, message, tag);
    }
  }

  /// Authentication logging
  static void auth(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_authPrefix, message, tag);
    }
  }

  /// Data operations logging
  static void data(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_dataPrefix, message, tag);
    }
  }

  // ==================== SPECIALIZED LOGGING ====================

  /// Log method entry
  static void methodEntry(String methodName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      String message = 'Entering $methodName';
      if (parameters != null && parameters.isNotEmpty) {
        message += ' with parameters: $parameters';
      }
      _log(_debugPrefix, message);
    }
  }

  /// Log method exit
  static void methodExit(String methodName, {dynamic returnValue}) {
    if (kDebugMode) {
      String message = 'Exiting $methodName';
      if (returnValue != null) {
        message += ' with return value: $returnValue';
      }
      _log(_debugPrefix, message);
    }
  }

  /// Log API request
  static void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      String message = '$method $url';
      if (data != null) {
        message += ' | Data: $data';
      }
      _log(_apiPrefix, message);
    }
  }

  /// Log API response
  static void apiResponse(int statusCode, String url, {dynamic data}) {
    if (kDebugMode) {
      String message = '$statusCode $url';
      if (data != null) {
        message += ' | Response: $data';
      }
      _log(_apiPrefix, message);
    }
  }

  /// Log BLoC event
  static void blocEvent(String eventName, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      String message = 'Event: $eventName';
      if (data != null) {
        message += ' | Data: $data';
      }
      _log(_blocPrefix, message);
    }
  }

  /// Log BLoC state change
  static void blocStateChange(String stateName, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      String message = 'State: $stateName';
      if (data != null) {
        message += ' | Data: $data';
      }
      _log(_blocPrefix, message);
    }
  }

  /// Log navigation
  static void navigation(String from, String to, {Map<String, dynamic>? arguments}) {
    if (kDebugMode) {
      String message = 'Navigating from $from to $to';
      if (arguments != null) {
        message += ' | Arguments: $arguments';
      }
      _log(_navPrefix, message);
    }
  }

  /// Log user action
  static void userAction(String action, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      String message = 'User action: $action';
      if (data != null) {
        message += ' | Data: $data';
      }
      _log(_uiPrefix, message);
    }
  }

  // ==================== PRIVATE METHODS ====================

  static void _log(String prefix, String message, [String? tag]) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag != null ? '[$tag] ' : '';
    print('$timestamp $prefix $tagStr$message');
  }

  // ==================== UTILITY METHODS ====================

  /// Log performance timing
  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      _log(_debugPrefix, 'Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// Log memory usage (if available)
  static void memory(String context) {
    if (kDebugMode) {
      _log(_debugPrefix, 'Memory check: $context');
    }
  }

  /// Log network status
  static void network(String status, {String? details}) {
    if (kDebugMode) {
      String message = 'Network: $status';
      if (details != null) {
        message += ' | $details';
      }
      _log(_debugPrefix, message);
    }
  }
}
