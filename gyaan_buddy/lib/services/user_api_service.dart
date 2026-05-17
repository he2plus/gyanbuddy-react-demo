import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'web_network_service.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';
import 'token_storage_service.dart';
import '../utils/error_message_helper.dart';
import '../utils/env.dart';

// API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJson(json['data']) : null,
      statusCode: json['status_code'],
    );
  }
}

// Leaderboard response wrapper
class LeaderboardResponse {
  final List<User> users;
  final String? className;
  final String? gradeName;

  LeaderboardResponse({
    required this.users,
    this.className,
    this.gradeName,
  });
}

class UserApiService extends ApiService {
  static const String _basePath = '/users';

  // Use web-specific network helper for web platform
  late final WebNetworkHelper _webHelper;

  UserApiService() {
    if (kIsWeb) {
      _webHelper = WebNetworkHelper();
    }
  }

  void _log(String message) {
    if (kDebugMode && Env.enableNetworkLogging) {
      debugPrint(message);
    }
  }

  // Login user
  Future<ApiResponse<User>> login(Map<String, dynamic> data) async {
    try {
      final response = await post(
        '/auth/login/',
        data: data,
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        // Extract user data from the nested structure
        final userData = responseData['data']['user'];
        final tokensData = responseData['data']['tokens'];

        // Save tokens to shared preferences
        await TokenStorageService.saveTokens(
          accessToken: tokensData['access'],
          refreshToken: tokensData['refresh'],
          accessTokenExpires:
              DateTime.parse(tokensData['access_token_expires']),
          refreshTokenExpires:
              DateTime.parse(tokensData['refresh_token_expires']),
        );

        // Set auth token for current session
        setAuthToken(tokensData['access']);

        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Login successful',
          data: User.fromJson(userData),
        );
      } else {
        // Handle validation errors
        final errors = responseData['errors'] ?? {};
        final errorMessage = _formatErrors(errors);

        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  String _formatErrors(Map<String, dynamic> errors) {
    if (errors.isEmpty) return 'Login failed. Please check your credentials.';

    return ErrorMessageHelper.formatValidationErrors(errors);
  }

  // Register user
  Future<ApiResponse<User>> register(Map<String, dynamic> data) async {
    try {
      final response = await post(
        '/auth/register',
        data: data,
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        // Extract user data from the nested structure
        final userData = responseData['data']['user'];
        final tokensData = responseData['data']['tokens'];

        // Save tokens to shared preferences
        await TokenStorageService.saveTokens(
          accessToken: tokensData['access'],
          refreshToken: tokensData['refresh'],
          accessTokenExpires:
              DateTime.parse(tokensData['access_token_expires']),
          refreshTokenExpires:
              DateTime.parse(tokensData['refresh_token_expires']),
        );

        // Set auth token for current session
        setAuthToken(tokensData['access']);

        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Registration successful',
          data: User.fromJson(userData),
        );
      } else {
        // Handle validation errors
        final errors = responseData['errors'] ?? {};
        final errorMessage = _formatErrors(errors);

        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await get('$_basePath/me');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final userData = responseData['data'];

        return ApiResponse(
          success: true,
          message:
              responseData['message'] ?? 'User data retrieved successfully',
          data: User.fromJson(userData),
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to get user data',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? email,
    String? profileImage,
    bool? loggedInOnce,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (profileImage != null) data['profile_image'] = profileImage;
      if (loggedInOnce != null) data['logged_in_once'] = loggedInOnce;

      final response = await put(
        '$_basePath/me',
        data: data,
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await put(
        '$_basePath/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await post('$_basePath/logout');

      // Clear auth token
      clearAuthToken();

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Delete user account
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await delete('$_basePath/me');

      // Clear auth token
      clearAuthToken();

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Get user by ID (admin function)
  Future<ApiResponse<User>> getUserById(String userId) async {
    try {
      final response = await get('$_basePath/$userId');

      return ApiResponse.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Get all users (admin function)
  Future<ApiResponse<List<User>>> getAllUsers({
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null) queryParams['search'] = search;

      final response = await get(
        '$_basePath',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => (json['users'] as List)
            .map((userJson) => User.fromJson(userJson))
            .toList(),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Get leaderboard
  Future<ApiResponse<LeaderboardResponse>> getLeaderboard({
    int? page,
    int? limit,
    String? period, // daily, weekly, monthly, all-time
    String? grade,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (period != null) queryParams['period'] = period;
      if (grade != null) queryParams['grade'] = grade;

      final response = await get(
        '$_basePath/leaderboard/',
        queryParameters: queryParams,
      );

      // Debug logging
      _log('Leaderboard API response received');
      _log('Response data type: ${response.data.runtimeType}');

      final responseData = response.data;
      _log('Response data keys: ${responseData.keys.toList()}');

      // Check if response has the expected structure
      if (responseData == null) {
        return ApiResponse(
          success: false,
          message: 'No response data received',
        );
      }

      // Check if response indicates success
      // Note: Some APIs don't include 'success' field, so we only fail if explicitly false
      if (responseData.containsKey('success') &&
          responseData['success'] == false) {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'API request failed',
          statusCode: responseData['status_code'],
        );
      }

      // Extract grade_name and class_name from response
      String? className;
      String? gradeName;

      // Try to extract from responseData directly
      if (responseData['class_name'] != null) {
        className = responseData['class_name'].toString();
      }
      if (responseData['grade_name'] != null) {
        gradeName = responseData['grade_name'].toString();
      }

      // Also try to extract from data object if it exists
      if (responseData['data'] is Map) {
        final dataMap = responseData['data'] as Map;
        if (className == null && dataMap['class_name'] != null) {
          className = dataMap['class_name'].toString();
        }
        if (gradeName == null && dataMap['grade_name'] != null) {
          gradeName = dataMap['grade_name'].toString();
        }
      }

      _log('Extracted class_name: $className, grade_name: $gradeName');

      // Handle different response structures
      List<dynamic> usersList;

      if (responseData['data'] is List) {
        // Case 1: data is directly a list of users
        _log(
            'Data is directly a list of users, length: ${(responseData['data'] as List).length}');
        usersList = responseData['data'] as List;
      } else if (responseData['data'] is Map &&
          responseData['data']['results'] is List) {
        // Case 2: data.results is a list (current API structure)
        _log(
            'Data.results is a list of users, length: ${(responseData['data']['results'] as List).length}');
        usersList = responseData['data']['results'] as List;
      } else if (responseData['data'] is Map &&
          responseData['data']['users'] is List) {
        // Case 3: data.users is a list (alternative structure)
        _log(
            'Data.users is a list of users, length: ${(responseData['data']['users'] as List).length}');
        usersList = responseData['data']['users'] as List;
      } else if (responseData['users'] is List) {
        // Case 4: users is directly in the response
        _log(
            'Users is directly in response, length: ${(responseData['users'] as List).length}');
        usersList = responseData['users'] as List;
      } else {
        _log('No users list found in response');
        _log('Data type: ${responseData['data']?.runtimeType}');
        if (responseData['data'] is Map) {
          _log('Data keys: ${(responseData['data'] as Map).keys.toList()}');
        }
        return ApiResponse(
          success: false,
          message: 'No users data found in response',
        );
      }

      final users = <User>[];

      for (int i = 0; i < usersList.length; i++) {
        try {
          final userJson = usersList[i];
          _log('Parsing leaderboard user $i');

          // Test minimal user creation first
          if (userJson is Map<String, dynamic>) {
            _log('User $i keys: ${userJson.keys.toList()}');
            _log('User $i id type: ${userJson['id'].runtimeType}');
            _log(
                'User $i total_exp type: ${userJson['total_exp'].runtimeType}');
          }

          final user = User.fromLeaderboardJson(userJson);
          users.add(user);
          _log('Successfully parsed leaderboard user $i');
        } catch (parseError) {
          _log('Error parsing user $i: $parseError');
          // Continue with other users instead of failing completely
        }
      }

      if (users.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'No users could be parsed from response',
        );
      }

      final leaderboardResponse = LeaderboardResponse(
        users: users,
        className: className,
        gradeName: gradeName,
      );

      _log('🔵 Leaderboard API: Returning success with ${users.length} users');
      _log(
          '🔵 Leaderboard API: Class name: $className, Grade name: $gradeName');

      return ApiResponse(
        success: true,
        message: responseData['message'] ?? 'Leaderboard loaded successfully',
        data: leaderboardResponse,
        statusCode: responseData['status_code'],
      );
    } catch (e) {
      _log('Leaderboard API Error: $e');
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response = await post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Reset password
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }

  // Get user missions
  Future<ApiResponse<List<Mission>>> getUserMissions() async {
    try {
      _log('Calling missions API...');
      final response = await get('/missions/');

      final responseData = response.data;
      _log('Raw mission API response received');

      // Check for both possible response formats
      final isSuccess = responseData['success'] == true ||
          responseData['status'] == 'success';

      if (isSuccess) {
        final missionsList = responseData['data'] as List;
        _log('Found ${missionsList.length} missions in response');

        final missions = missionsList.map((missionJson) {
          try {
            return Mission.fromJson(missionJson);
          } catch (e) {
            _log('Error parsing mission: $e');
            rethrow;
          }
        }).toList();

        _log('Successfully parsed ${missions.length} missions');

        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Missions retrieved successfully',
          data: missions,
        );
      } else {
        _log('API returned failure: ${responseData['message']}');
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to retrieve missions',
        );
      }
    } catch (e) {
      _log('Exception in getUserMissions: $e');
      return ApiResponse(
        success: false,
        message: ErrorMessageHelper.getErrorMessage(e),
      );
    }
  }
}
