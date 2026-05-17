import 'package:shared_preferences/shared_preferences.dart';
import 'global_logout_service.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiresKey = 'access_token_expires';
  static const String _refreshTokenExpiresKey = 'refresh_token_expires';

  // Initialize SharedPreferences with error handling
  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      return null;
    }
  }

  // Save tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpires,
    required DateTime refreshTokenExpires,
  }) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    
    try {
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_accessTokenExpiresKey, accessTokenExpires.toIso8601String());
      await prefs.setString(_refreshTokenExpiresKey, refreshTokenExpires.toIso8601String());
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    
    try {
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    
    try {
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  // Get access token expiry
  static Future<DateTime?> getAccessTokenExpires() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    
    try {
      final expiresString = prefs.getString(_accessTokenExpiresKey);
      if (expiresString != null) {
        return DateTime.parse(expiresString);
      }
      return null;
    } catch (e) {
      print('Error getting access token expires: $e');
      return null;
    }
  }

  // Get refresh token expiry
  static Future<DateTime?> getRefreshTokenExpires() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    
    try {
      final expiresString = prefs.getString(_refreshTokenExpiresKey);
      if (expiresString != null) {
        return DateTime.parse(expiresString);
      }
      return null;
    } catch (e) {
      print('Error getting refresh token expires: $e');
      return null;
    }
  }

  // Check if access token is expired
  static Future<bool> isAccessTokenExpired() async {
    final expires = await getAccessTokenExpires();
    if (expires == null) return true;
    return DateTime.now().isAfter(expires);
  }

  // Check if refresh token is expired
  static Future<bool> isRefreshTokenExpired() async {
    final expires = await getRefreshTokenExpires();
    if (expires == null) return true;
    return DateTime.now().isAfter(expires);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return false;
      
      final isExpired = await isAccessTokenExpired();
      if (isExpired) {
        // Token is expired, trigger automatic logout
        await GlobalLogoutService.logout();
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
  
  // Check token expiration and trigger logout if needed
  static Future<void> checkTokenExpiration() async {
    try {
      final isExpired = await isAccessTokenExpired();
      if (isExpired) {
        await GlobalLogoutService.logout();
      }
    } catch (e) {
      print('Error checking token expiration: $e');
    }
  }

  // Clear all tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    
    try {
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_accessTokenExpiresKey);
      await prefs.remove(_refreshTokenExpiresKey);
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  // Get all tokens
  static Future<Map<String, dynamic>?> getAllTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final accessExpires = await getAccessTokenExpires();
      final refreshExpires = await getRefreshTokenExpires();

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'access_token_expires': accessExpires?.toIso8601String(),
        'refresh_token_expires': refreshExpires?.toIso8601String(),
      };
    } catch (e) {
      print('Error getting all tokens: $e');
      return null;
    }
  }
}
