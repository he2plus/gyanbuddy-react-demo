import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../utils/env.dart';
import '../services/token_storage_service.dart';
import 'global_logout_service.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio();
    _setupDio();
  }

  void _setupDio() {
    // Base configuration
    _dio.options.baseUrl = Env.fullBaseUrl;
    _dio.options.connectTimeout = Duration(seconds: Env.connectTimeout);
    _dio.options.receiveTimeout = Duration(seconds: Env.receiveTimeout);
    _dio.options.sendTimeout = Duration(seconds: Env.sendTimeout);

    if (kDebugMode && Env.enableNetworkLogging) {
      debugPrint('🔵 ApiService: Base URL set to: ${_dio.options.baseUrl}');
      debugPrint('🔵 ApiService: Development mode: ${Env.isDevelopment}');
    }

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode && Env.enableNetworkLogging)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
    ]);

    if (kDebugMode && Env.enableNetworkLogging) {
      debugPrint(
        '🔵 ApiService: Interceptors added. PrettyDioLogger enabled: ${Env.enableNetworkLogging}',
      );
    }
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (kDebugMode && Env.enableNetworkLogging) {
      debugPrint('🔵 ApiService: GET request to path: $path');
      debugPrint('🔵 ApiService: Query parameters: $queryParameters');
    }

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      if (kDebugMode && Env.enableNetworkLogging) {
        debugPrint('🔵 ApiService: GET request completed successfully');
      }
      return response;
    } catch (e) {
      if (kDebugMode && Env.enableNetworkLogging) {
        debugPrint('🔵 ApiService: GET request failed with error: $e');
      }
      handleError(e);
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      handleError(e);
      rethrow;
    }
  }

  void handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw TimeoutException('Request timeout');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final message = error.response?.statusMessage ?? 'Bad response';

          // Handle unauthorized responses
          if (statusCode == 401 || statusCode == 403) {
            // The AuthInterceptor will handle the logout, so we just throw the exception
            throw UnauthorizedException(
                statusCode, message, error.response?.data);
          }

          throw ApiException(statusCode, message, error.response?.data);
        case DioExceptionType.cancel:
          throw CancelException('Request cancelled');
        case DioExceptionType.connectionError:
          throw NetworkException('No internet connection');
        case DioExceptionType.badCertificate:
          throw CertificateException('Bad certificate');
        case DioExceptionType.unknown:
        default:
          throw UnknownException('Unknown error occurred');
      }
    } else {
      throw UnknownException('Unknown error occurred');
    }
  }

  // Helper method to add headers
  void addHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  // Helper method to set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Helper method to clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

// Custom exception classes
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException(this.statusCode, this.message, this.data);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

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

class UnauthorizedException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  UnauthorizedException(this.statusCode, this.message, this.data);

  @override
  String toString() => 'UnauthorizedException: $statusCode - $message';
}

// Auth interceptor for handling authentication
class _AuthInterceptor extends Interceptor {
  // List of endpoints that should NOT have Authorization header
  static const List<String> _publicEndpoints = [
    '/auth/login/',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  // Check if the request path is a public endpoint
  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Add any default headers here
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    // Remove Authorization header for public authentication endpoints
    // This ensures login/register requests don't include tokens
    if (_isPublicEndpoint(options.path)) {
      options.headers.remove('Authorization');
    } else {
      // Automatically set stored token if available for protected endpoints
      try {
        final accessToken = await TokenStorageService.getAccessToken();
        if (accessToken != null &&
            !await TokenStorageService.isAccessTokenExpired()) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      } catch (e) {
        // Ignore token errors, continue without auth header
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle successful responses
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle unauthorized errors (401, 403) and token expiration
    // But skip for public endpoints (login, register, etc.) as 401 is expected there
    if ((err.response?.statusCode == 401 || err.response?.statusCode == 403) &&
        !_isPublicEndpoint(err.requestOptions.path)) {
      await _handleUnauthorizedError();
    }

    // Handle errors globally
    handler.next(err);
  }

  Future<void> _handleUnauthorizedError() async {
    try {
      // Clear all stored tokens
      await TokenStorageService.clearTokens();

      // Trigger global logout
      await GlobalLogoutService.logout();
    } catch (e) {
      // Ignore errors during logout process
      print('Error during automatic logout: $e');
    }
  }
}
