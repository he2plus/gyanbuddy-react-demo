import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/env.dart';
import '../utils/web_config.dart';

/// Web-specific network helper that handles CORS and web connectivity issues
class WebNetworkHelper {
  static final WebNetworkHelper _instance = WebNetworkHelper._internal();
  factory WebNetworkHelper() => _instance;
  WebNetworkHelper._internal() {
    // Auto-initialize when created
    initialize();
  }

  Dio? _webDio;
  bool _isInitialized = false;

  /// Initialize web-specific Dio instance
  void initialize() {
    if (WebConfig.isWeb && !_isInitialized) {
      _webDio = Dio();
      _setupWebDio();
      _isInitialized = true;
    }
  }

  void _setupWebDio() {
    if (!WebConfig.isWeb || _webDio == null) return;
    
    // Web-specific configurations
    _webDio!.options.baseUrl = Env.fullBaseUrl;
    
    // Add web-specific headers from configuration
    final webHeaders = WebConfig.webHeaders;
    _webDio!.options.headers.addAll(webHeaders);
    
    // Set mode to cors for web
    _webDio!.options.headers['mode'] = 'cors';
    
    // Add credentials for web (web-specific)
    // Note: withCredentials is not available in Flutter's Dio, but the headers will handle CORS
    
    // Set web-specific timeouts
    _webDio!.options.connectTimeout = Duration(seconds: WebConfig.getTimeout('connect', Env.connectTimeout));
    _webDio!.options.receiveTimeout = Duration(seconds: WebConfig.getTimeout('receive', Env.receiveTimeout));
    _webDio!.options.sendTimeout = Duration(seconds: WebConfig.getTimeout('send', Env.sendTimeout));
  }

  /// Check if the web app has internet connectivity
  Future<bool> hasInternetConnection() async {
    if (!WebConfig.isWeb) return true;
    
    // On web, use browser's navigator.onLine as primary check
    // Avoid making external HTTP requests that can fail due to CORS
    // The actual API calls will fail with proper errors if there's no connectivity
    try {
      // For web, we assume connectivity is OK and let actual API calls handle failures
      // This avoids CORS issues with connectivity checks
      if (kDebugMode) {
        print('Web connectivity: assuming online (actual API calls will verify)');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Web connectivity check error: $e');
      }
      // Default to true - let actual API calls fail with proper error handling
      return true;
    }
  }

  /// Enhanced error handling for web
  void handleWebError(dynamic error) {
    if (WebConfig.isWeb) {
      // Web-specific error handling
      if (error is DioException) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw TimeoutException(WebConfig.getErrorMessage('timeout'));
          case DioExceptionType.badResponse:
            if (error.response?.statusCode == 0) {
              // Status code 0 usually means CORS or network issue on web
              throw NetworkException(WebConfig.getErrorMessage('corsError'));
            }
            throw ApiException(
              error.response?.statusCode ?? 500,
              error.response?.statusMessage ?? 'Bad response',
              error.response?.data,
            );
          case DioExceptionType.cancel:
            throw CancelException('Request cancelled');
          case DioExceptionType.connectionError:
            throw NetworkException(WebConfig.getErrorMessage('noConnection'));
          case DioExceptionType.badCertificate:
            throw CertificateException('Bad certificate - this might be a development environment issue');
          case DioExceptionType.unknown:
          default:
            // Check if it's a CORS error
            if (error.message?.contains('CORS') == true || 
                error.message?.contains('cross-origin') == true) {
              throw NetworkException(WebConfig.getErrorMessage('corsError'));
            }
            throw UnknownException(WebConfig.getErrorMessage('unknown'));
        }
      } else {
        throw UnknownException(WebConfig.getErrorMessage('unknown'));
      }
    }
  }

  /// Get web-specific Dio instance
  Dio? get webDio => WebConfig.isWeb ? _webDio : null;

  /// Check if web network helper is available
  bool get isAvailable => WebConfig.isWeb && _isInitialized && _webDio != null;
}

/// Web-specific exception for better error messages
class WebNetworkException implements Exception {
  final String message;
  final String? suggestion;
  
  WebNetworkException(this.message, {this.suggestion});
  
  @override
  String toString() {
    if (suggestion != null) {
      return '$message\nSuggestion: $suggestion';
    }
    return message;
  }
}

// Import the exception classes from api_service.dart
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  
  ApiException(this.statusCode, this.message, this.data);
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class CancelException implements Exception {
  final String message;
  CancelException(this.message);
  
  @override
  String toString() => 'CancelException: $message';
}

class CertificateException implements Exception {
  final String message;
  CertificateException(this.message);
  
  @override
  String toString() => 'CertificateException: $message';
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
  
  @override
  String toString() => 'UnknownException: $message';
}
