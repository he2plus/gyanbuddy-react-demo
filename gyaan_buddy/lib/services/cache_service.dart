import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache configuration constants
class CacheConfig {
  /// Default cache expiration time in minutes
  static const int defaultExpirationMinutes = 30;
  static const int missionsExpirationMinutes = 5;

  /// Cache keys
  static const String userCacheKey = 'cache_user';
  static const String subjectsCacheKey = 'cache_subjects';
  static const String modulesCacheKey = 'cache_modules';
  static const String leaderboardCacheKey = 'cache_leaderboard';
  static const String missionsCacheKey = 'cache_missions';
  static const String chaptersCacheKey = 'cache_chapters';

  /// Cache timestamp keys
  static const String userCacheTimestampKey = 'cache_user_timestamp';
  static const String subjectsCacheTimestampKey = 'cache_subjects_timestamp';
  static const String modulesCacheTimestampKey = 'cache_modules_timestamp';
  static const String leaderboardCacheTimestampKey =
      'cache_leaderboard_timestamp';
  static const String missionsCacheTimestampKey = 'cache_missions_timestamp';
  static const String chaptersCacheTimestampKey = 'cache_chapters_timestamp';
}

/// A service to handle caching of API responses to local storage
class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  /// Singleton instance
  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  CacheService._();

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _missionsCacheKey({int? month, int? year}) {
    if (month == null && year == null) return CacheConfig.missionsCacheKey;
    final now = DateTime.now();
    return '${CacheConfig.missionsCacheKey}_${year ?? now.year}_${month ?? now.month}';
  }

  String _missionsCacheTimestampKey({int? month, int? year}) {
    if (month == null && year == null) {
      return CacheConfig.missionsCacheTimestampKey;
    }
    final now = DateTime.now();
    return '${CacheConfig.missionsCacheTimestampKey}_${year ?? now.year}_${month ?? now.month}';
  }

  // ==================== GENERIC CACHE OPERATIONS ====================

  /// Save data to cache with timestamp
  Future<bool> saveToCache({
    required String key,
    required String timestampKey,
    required dynamic data,
  }) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(data);
      final timestamp = DateTime.now().toIso8601String();

      await prefs.setString(key, jsonString);
      await prefs.setString(timestampKey, timestamp);

      print('✅ CacheService: Saved data to $key');
      return true;
    } catch (e) {
      print('❌ CacheService: Error saving to cache ($key): $e');
      return false;
    }
  }

  /// Get data from cache
  Future<dynamic> getFromCache({
    required String key,
    required String timestampKey,
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(key);
      final timestampString = prefs.getString(timestampKey);

      if (jsonString == null || timestampString == null) {
        print('📭 CacheService: No cache found for $key');
        return null;
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp).inMinutes;

      if (difference > expirationMinutes) {
        print(
            '⏰ CacheService: Cache expired for $key (${difference}min > ${expirationMinutes}min)');
        return null;
      }

      print('✅ CacheService: Cache hit for $key (age: ${difference}min)');
      return jsonDecode(jsonString);
    } catch (e) {
      print('❌ CacheService: Error reading from cache ($key): $e');
      return null;
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid({
    required String key,
    required String timestampKey,
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(key);
      final timestampString = prefs.getString(timestampKey);

      if (jsonString == null || timestampString == null) {
        return false;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp).inMinutes;

      return difference <= expirationMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Clear specific cache
  Future<void> clearCache({
    required String key,
    required String timestampKey,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
      await prefs.remove(timestampKey);
      print('🗑️ CacheService: Cleared cache for $key');
    } catch (e) {
      print('❌ CacheService: Error clearing cache ($key): $e');
    }
  }

  // ==================== USER CACHE ====================

  /// Save user data to cache
  Future<bool> saveUserCache(Map<String, dynamic> userData) async {
    return saveToCache(
      key: CacheConfig.userCacheKey,
      timestampKey: CacheConfig.userCacheTimestampKey,
      data: userData,
    );
  }

  /// Get user data from cache
  Future<Map<String, dynamic>?> getUserCache({
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: CacheConfig.userCacheKey,
      timestampKey: CacheConfig.userCacheTimestampKey,
      expirationMinutes: expirationMinutes,
    );
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Clear user cache
  Future<void> clearUserCache() async {
    await clearCache(
      key: CacheConfig.userCacheKey,
      timestampKey: CacheConfig.userCacheTimestampKey,
    );
  }

  // ==================== SUBJECTS CACHE ====================

  /// Save subjects data to cache
  Future<bool> saveSubjectsCache(
      List<Map<String, dynamic>> subjectsData) async {
    return saveToCache(
      key: CacheConfig.subjectsCacheKey,
      timestampKey: CacheConfig.subjectsCacheTimestampKey,
      data: subjectsData,
    );
  }

  /// Get subjects data from cache
  Future<List<Map<String, dynamic>>?> getSubjectsCache({
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: CacheConfig.subjectsCacheKey,
      timestampKey: CacheConfig.subjectsCacheTimestampKey,
      expirationMinutes: expirationMinutes,
    );
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  /// Clear subjects cache
  Future<void> clearSubjectsCache() async {
    await clearCache(
      key: CacheConfig.subjectsCacheKey,
      timestampKey: CacheConfig.subjectsCacheTimestampKey,
    );
  }

  // ==================== MODULES CACHE ====================

  /// Save modules data to cache (by subject ID)
  Future<bool> saveModulesCache(
      String subjectId, List<Map<String, dynamic>> modulesData) async {
    return saveToCache(
      key: '${CacheConfig.modulesCacheKey}_$subjectId',
      timestampKey: '${CacheConfig.modulesCacheTimestampKey}_$subjectId',
      data: modulesData,
    );
  }

  /// Get modules data from cache (by subject ID)
  Future<List<Map<String, dynamic>>?> getModulesCache(
    String subjectId, {
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: '${CacheConfig.modulesCacheKey}_$subjectId',
      timestampKey: '${CacheConfig.modulesCacheTimestampKey}_$subjectId',
      expirationMinutes: expirationMinutes,
    );
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  /// Clear modules cache for a specific subject
  Future<void> clearModulesCache(String subjectId) async {
    await clearCache(
      key: '${CacheConfig.modulesCacheKey}_$subjectId',
      timestampKey: '${CacheConfig.modulesCacheTimestampKey}_$subjectId',
    );
  }

  /// Save all modules cache (combined map of subjectId -> modules)
  Future<bool> saveAllModulesCache(
      Map<String, List<Map<String, dynamic>>> allModules) async {
    return saveToCache(
      key: '${CacheConfig.modulesCacheKey}_all',
      timestampKey: '${CacheConfig.modulesCacheTimestampKey}_all',
      data: allModules,
    );
  }

  /// Get all modules cache
  Future<Map<String, List<Map<String, dynamic>>>?> getAllModulesCache({
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: '${CacheConfig.modulesCacheKey}_all',
      timestampKey: '${CacheConfig.modulesCacheTimestampKey}_all',
      expirationMinutes: expirationMinutes,
    );
    if (data != null && data is Map) {
      final result = <String, List<Map<String, dynamic>>>{};
      data.forEach((key, value) {
        if (value is List) {
          result[key.toString()] =
              value.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      });
      return result;
    }
    return null;
  }

  // ==================== LEADERBOARD CACHE ====================

  /// Save leaderboard data to cache
  Future<bool> saveLeaderboardCache(
      Map<String, dynamic> leaderboardData) async {
    return saveToCache(
      key: CacheConfig.leaderboardCacheKey,
      timestampKey: CacheConfig.leaderboardCacheTimestampKey,
      data: leaderboardData,
    );
  }

  /// Get leaderboard data from cache
  Future<Map<String, dynamic>?> getLeaderboardCache({
    int expirationMinutes = 15, // Leaderboard expires faster
  }) async {
    final data = await getFromCache(
      key: CacheConfig.leaderboardCacheKey,
      timestampKey: CacheConfig.leaderboardCacheTimestampKey,
      expirationMinutes: expirationMinutes,
    );
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Clear leaderboard cache
  Future<void> clearLeaderboardCache() async {
    await clearCache(
      key: CacheConfig.leaderboardCacheKey,
      timestampKey: CacheConfig.leaderboardCacheTimestampKey,
    );
  }

  // ==================== MISSIONS CACHE ====================

  /// Save missions data to cache
  Future<bool> saveMissionsCache(
    List<Map<String, dynamic>> missionsData, {
    int? month,
    int? year,
  }) async {
    return saveToCache(
      key: _missionsCacheKey(month: month, year: year),
      timestampKey: _missionsCacheTimestampKey(month: month, year: year),
      data: missionsData,
    );
  }

  /// Get missions data from cache
  Future<List<Map<String, dynamic>>?> getMissionsCache({
    int? month,
    int? year,
    int expirationMinutes = CacheConfig.missionsExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: _missionsCacheKey(month: month, year: year),
      timestampKey: _missionsCacheTimestampKey(month: month, year: year),
      expirationMinutes: expirationMinutes,
    );
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  /// Clear missions cache
  Future<void> clearMissionsCache({int? month, int? year}) async {
    await clearCache(
      key: _missionsCacheKey(month: month, year: year),
      timestampKey: _missionsCacheTimestampKey(month: month, year: year),
    );
  }

  // ==================== CHAPTERS CACHE ====================

  /// Save chapters data to cache (by module ID)
  Future<bool> saveChaptersCache(
      String moduleId, List<Map<String, dynamic>> chaptersData) async {
    return saveToCache(
      key: '${CacheConfig.chaptersCacheKey}_$moduleId',
      timestampKey: '${CacheConfig.chaptersCacheTimestampKey}_$moduleId',
      data: chaptersData,
    );
  }

  /// Get chapters data from cache (by module ID)
  Future<List<Map<String, dynamic>>?> getChaptersCache(
    String moduleId, {
    int expirationMinutes = CacheConfig.defaultExpirationMinutes,
  }) async {
    final data = await getFromCache(
      key: '${CacheConfig.chaptersCacheKey}_$moduleId',
      timestampKey: '${CacheConfig.chaptersCacheTimestampKey}_$moduleId',
      expirationMinutes: expirationMinutes,
    );
    if (data != null && data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  /// Clear chapters cache for a specific module
  Future<void> clearChaptersCache(String moduleId) async {
    await clearCache(
      key: '${CacheConfig.chaptersCacheKey}_$moduleId',
      timestampKey: '${CacheConfig.chaptersCacheTimestampKey}_$moduleId',
    );
  }

  // ==================== CLEAR ALL CACHE ====================

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await _getPrefs();

      // Get all keys and remove cache-related ones
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('cache_')) {
          await prefs.remove(key);
        }
      }

      print('🗑️ CacheService: Cleared all cache');
    } catch (e) {
      print('❌ CacheService: Error clearing all cache: $e');
    }
  }

  /// Invalidate all cache (force refresh on next access)
  Future<void> invalidateAllCache() async {
    await clearAllCache();
  }
}
