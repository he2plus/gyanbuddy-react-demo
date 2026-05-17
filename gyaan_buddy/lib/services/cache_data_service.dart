import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'user_api_service.dart';
import 'subject_api_service.dart';
import 'mission_api_service.dart';
import 'module_content_api_service.dart';
import '../models/user_model.dart';
import '../models/subject_model.dart';
import '../models/module_model.dart';
import '../models/module_status.dart';
import '../models/mission_model.dart';
import '../models/module_chapter_model.dart';

/// Result of a cache operation
class CacheResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final bool fromCache;

  const CacheResult({
    required this.success,
    this.data,
    this.error,
    this.fromCache = false,
  });

  factory CacheResult.fromCache(T data) => CacheResult(
        success: true,
        data: data,
        fromCache: true,
      );

  factory CacheResult.fromApi(T data) => CacheResult(
        success: true,
        data: data,
        fromCache: false,
      );

  factory CacheResult.failure(String error) => CacheResult(
        success: false,
        error: error,
      );
}

/// Overall status of cache prefetching
class CachePrefetchStatus {
  final bool userSuccess;
  final bool subjectsSuccess;
  final bool modulesSuccess;
  final bool leaderboardSuccess;
  final List<String> errors;

  const CachePrefetchStatus({
    this.userSuccess = false,
    this.subjectsSuccess = false,
    this.modulesSuccess = false,
    this.leaderboardSuccess = false,
    this.errors = const [],
  });

  bool get allSuccess =>
      userSuccess && subjectsSuccess && modulesSuccess && leaderboardSuccess;

  bool get anySuccess =>
      userSuccess || subjectsSuccess || modulesSuccess || leaderboardSuccess;

  int get successCount {
    int count = 0;
    if (userSuccess) count++;
    if (subjectsSuccess) count++;
    if (modulesSuccess) count++;
    if (leaderboardSuccess) count++;
    return count;
  }

  CachePrefetchStatus copyWith({
    bool? userSuccess,
    bool? subjectsSuccess,
    bool? modulesSuccess,
    bool? leaderboardSuccess,
    List<String>? errors,
  }) {
    return CachePrefetchStatus(
      userSuccess: userSuccess ?? this.userSuccess,
      subjectsSuccess: subjectsSuccess ?? this.subjectsSuccess,
      modulesSuccess: modulesSuccess ?? this.modulesSuccess,
      leaderboardSuccess: leaderboardSuccess ?? this.leaderboardSuccess,
      errors: errors ?? this.errors,
    );
  }

  @override
  String toString() {
    return 'CachePrefetchStatus(user: $userSuccess, subjects: $subjectsSuccess, modules: $modulesSuccess, leaderboard: $leaderboardSuccess, errors: ${errors.length})';
  }
}

/// Service to fetch and cache API data
/// Handles both prefetching on splash screen and providing cached data
class CacheDataService {
  static CacheDataService? _instance;

  final CacheService _cacheService;
  final UserApiService _userApiService;
  final SubjectApiService _subjectApiService;
  final MissionApiService _missionApiService;
  final ModuleContentApiService _moduleContentApiService;
  Future<CacheResult<User>>? _userRequest;
  Future<CacheResult<List<Subject>>>? _subjectsRequest;
  Future<CacheResult<LeaderboardResponse>>? _leaderboardRequest;
  final Map<String, Future<CacheResult<List<Module>>>> _moduleRequests = {};
  final Map<String, Future<CacheResult<List<Mission>>>> _missionRequests = {};

  /// Singleton instance
  static CacheDataService get instance {
    _instance ??= CacheDataService._();
    return _instance!;
  }

  CacheDataService._()
      : _cacheService = CacheService.instance,
        _userApiService = UserApiService(),
        _subjectApiService = SubjectApiService(),
        _missionApiService = MissionApiService(),
        _moduleContentApiService = ModuleContentApiService();

  /// Initialize the service
  Future<void> initialize() async {
    await _cacheService.initialize();
  }

  // ==================== PREFETCH ALL DATA ====================

  /// Prefetch all data for the splash screen
  /// This fetches user, subjects, modules, and leaderboard data
  /// and caches them for later use
  /// Note: Missions are not prefetched at startup. The mission screen uses
  /// month-scoped cache and refreshes from the API after cache hits.
  Future<CachePrefetchStatus> prefetchAllData({
    VoidCallback? onProgress,
  }) async {
    if (kDebugMode) {
      print('🚀 CacheDataService: Starting prefetch of all data...');
    }

    CachePrefetchStatus status = const CachePrefetchStatus();
    final errors = <String>[];

    try {
      // Fetch all data in parallel for speed (excluding missions)
      final results = await Future.wait([
        _prefetchUser(),
        _prefetchSubjects(),
        _prefetchLeaderboard(),
      ], eagerError: false);

      // User result
      if (results[0] == true) {
        status = status.copyWith(userSuccess: true);
      } else {
        errors.add('Failed to prefetch user data');
      }

      // Subjects result
      List<Subject>? subjects;
      if (results[1] is List<Subject>) {
        subjects = results[1] as List<Subject>;
        status = status.copyWith(subjectsSuccess: true);
      } else {
        errors.add('Failed to prefetch subjects data');
      }

      // Leaderboard result
      if (results[2] == true) {
        status = status.copyWith(leaderboardSuccess: true);
      } else {
        errors.add('Failed to prefetch leaderboard data');
      }

      // Fetch modules for all subjects (after subjects are loaded)
      if (subjects != null && subjects.isNotEmpty) {
        final modulesSuccess = await _prefetchModulesForSubjects(subjects);
        status = status.copyWith(modulesSuccess: modulesSuccess);
        if (!modulesSuccess) {
          errors.add('Failed to prefetch some modules data');
        }
      }

      status = status.copyWith(errors: errors);

      if (kDebugMode) {
        print('✅ CacheDataService: Prefetch complete - $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error during prefetch: $e');
      }
      errors.add('Prefetch error: $e');
      status = status.copyWith(errors: errors);
    }

    return status;
  }

  // ==================== PREFETCH INDIVIDUAL DATA ====================

  /// Prefetch user data
  Future<bool> _prefetchUser() async {
    try {
      if (kDebugMode) {
        print('🔄 CacheDataService: Prefetching user data...');
      }

      final response = await getUser(forceRefresh: true);

      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('✅ CacheDataService: User data cached');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error prefetching user: $e');
      }
      return false;
    }
  }

  /// Prefetch subjects data
  Future<List<Subject>?> _prefetchSubjects() async {
    try {
      if (kDebugMode) {
        print('🔄 CacheDataService: Prefetching subjects data...');
      }

      final response = await getSubjects(forceRefresh: true);

      if (response.success && response.data != null) {
        if (kDebugMode) {
          print(
              '✅ CacheDataService: Subjects data cached (${response.data!.length} subjects)');
        }
        return response.data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error prefetching subjects: $e');
      }
      return null;
    }
  }

  /// Prefetch modules for all subjects
  Future<bool> _prefetchModulesForSubjects(List<Subject> subjects) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 CacheDataService: Prefetching modules for ${subjects.length} subjects...');
      }

      final allModules = <String, List<Map<String, dynamic>>>{};
      bool allSuccess = true;

      // Fetch modules for each subject in parallel (max 3 concurrent)
      for (int i = 0; i < subjects.length; i += 3) {
        final batch = subjects.skip(i).take(3).toList();
        final futures = batch.map((subject) async {
          try {
            final response = await getModules(subject.id, forceRefresh: true);
            if (response.success && response.data != null) {
              final modulesJson =
                  response.data!.map((m) => m.toJson()).toList();
              allModules[subject.id] = modulesJson;
              return true;
            }
            return false;
          } catch (e) {
            if (kDebugMode) {
              print(
                  '❌ CacheDataService: Error fetching modules for ${subject.name}: $e');
            }
            return false;
          }
        });

        final results = await Future.wait(futures);
        if (results.contains(false)) {
          allSuccess = false;
        }
      }

      // Save combined modules cache
      await _cacheService.saveAllModulesCache(allModules);

      if (kDebugMode) {
        print(
            '✅ CacheDataService: Modules data cached for ${allModules.length} subjects');
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error prefetching modules: $e');
      }
      return false;
    }
  }

  /// Prefetch leaderboard data
  Future<bool> _prefetchLeaderboard() async {
    try {
      if (kDebugMode) {
        print('🔄 CacheDataService: Prefetching leaderboard data...');
      }

      final response = await getLeaderboard(forceRefresh: true);

      if (response.success && response.data != null) {
        if (kDebugMode) {
          print(
              '✅ CacheDataService: Leaderboard data cached (${response.data!.users.length} users)');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error prefetching leaderboard: $e');
      }
      return false;
    }
  }

  // Note: Missions are no longer prefetched at startup.
  // They are cached per month and refreshed by the mission screen when needed.

  // ==================== GET CACHED DATA ====================

  /// Get user data (from cache or API)
  Future<CacheResult<User>> getUser({bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getUserCache();
        if (cachedData != null) {
          return CacheResult.fromCache(User.fromJson(cachedData));
        }
        if (_userRequest != null) {
          return _userRequest!;
        }
      }

      // Fetch from API
      final request = () async {
        final response = await _userApiService.getCurrentUser();
        if (response.success && response.data != null) {
          await _cacheService.saveUserCache(response.data!.toJson());
          return CacheResult.fromApi(response.data!);
        }

        return CacheResult<User>.failure(response.message);
      }();
      _userRequest = request;
      return await request;
    } catch (e) {
      return CacheResult.failure(e.toString());
    } finally {
      _userRequest = null;
    }
  }

  /// Get subjects data (from cache or API)
  Future<CacheResult<List<Subject>>> getSubjects(
      {bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getSubjectsCache();
        if (cachedData != null) {
          final subjects =
              cachedData.map((json) => Subject.fromJson(json)).toList();
          return CacheResult.fromCache(subjects);
        }
        if (_subjectsRequest != null) {
          return _subjectsRequest!;
        }
      }

      // Fetch from API
      final request = () async {
        final response = await _subjectApiService.getAllSubjects();
        if (response.success && response.data != null) {
          await _cacheService.saveSubjectsCache(
            response.data!.map((s) => s.toJson()).toList(),
          );
          return CacheResult.fromApi(response.data!);
        }

        return CacheResult<List<Subject>>.failure(response.message);
      }();
      _subjectsRequest = request;
      return await request;
    } catch (e) {
      return CacheResult.failure(e.toString());
    } finally {
      _subjectsRequest = null;
    }
  }

  /// Get modules data for a subject (from cache or API)
  Future<CacheResult<List<Module>>> getModules(
    String subjectId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getModulesCache(subjectId);
        if (cachedData != null) {
          final modules =
              cachedData.map((json) => Module.fromJson(json)).toList();
          return CacheResult.fromCache(modules);
        }
        final existingRequest = _moduleRequests[subjectId];
        if (existingRequest != null) {
          return existingRequest;
        }
      }

      // Fetch from API
      final request = () async {
        final response = await _subjectApiService.getSubjectModules(subjectId);
        if (response.success && response.data != null) {
          await _cacheService.saveModulesCache(
            subjectId,
            response.data!.map((m) => m.toJson()).toList(),
          );
          return CacheResult.fromApi(response.data!);
        }

        return CacheResult<List<Module>>.failure(response.message);
      }();
      _moduleRequests[subjectId] = request;
      return await request;
    } catch (e) {
      return CacheResult.failure(e.toString());
    } finally {
      _moduleRequests.remove(subjectId);
    }
  }

  /// Get leaderboard data (from cache or API)
  Future<CacheResult<LeaderboardResponse>> getLeaderboard(
      {bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getLeaderboardCache();
        if (cachedData != null) {
          final users = (cachedData['users'] as List)
              .map((json) => User.fromLeaderboardJson(json))
              .toList();
          return CacheResult.fromCache(LeaderboardResponse(
            users: users,
            className: cachedData['class_name'],
            gradeName: cachedData['grade_name'],
          ));
        }
        if (_leaderboardRequest != null) {
          return _leaderboardRequest!;
        }
      }

      // Fetch from API
      final request = () async {
        final response = await _userApiService.getLeaderboard();
        if (response.success && response.data != null) {
          final leaderboardJson = {
            'users': response.data!.users.map((u) => u.toJson()).toList(),
            'class_name': response.data!.className,
            'grade_name': response.data!.gradeName,
          };
          await _cacheService.saveLeaderboardCache(leaderboardJson);
          return CacheResult.fromApi(response.data!);
        }

        return CacheResult<LeaderboardResponse>.failure(response.message);
      }();
      _leaderboardRequest = request;
      return await request;
    } catch (e) {
      return CacheResult.failure(e.toString());
    } finally {
      _leaderboardRequest = null;
    }
  }

  /// Get missions data (from cache or API)
  Future<CacheResult<List<Mission>>> getMissions({
    bool forceRefresh = false,
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final cacheKey = '${year ?? now.year}_${month ?? now.month}';
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getMissionsCache(
          month: month,
          year: year,
        );
        if (cachedData != null) {
          final missions =
              cachedData.map((json) => Mission.fromJson(json)).toList();
          return CacheResult.fromCache(missions);
        }
        final existingRequest = _missionRequests[cacheKey];
        if (existingRequest != null) {
          return existingRequest;
        }
      }

      // Fetch from API
      final request = () async {
        final response = await _missionApiService.getAllMissions(
          month: month,
          year: year,
        );
        if (response.success && response.data != null) {
          await _cacheService.saveMissionsCache(
            response.data!.map((m) => m.toJson()).toList(),
            month: month,
            year: year,
          );
          return CacheResult.fromApi(response.data!);
        }

        return CacheResult<List<Mission>>.failure(response.message);
      }();
      _missionRequests[cacheKey] = request;
      return await request;
    } catch (e) {
      return CacheResult.failure(e.toString());
    } finally {
      _missionRequests.remove(cacheKey);
    }
  }

  // ==================== CHAPTERS CACHE ====================

  /// Get chapters data for a module (from cache or API)
  Future<CacheResult<List<ModuleChapter>>> getChapters(
    String moduleId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _cacheService.getChaptersCache(moduleId);
        if (cachedData != null) {
          final chapters =
              cachedData.map((json) => _chapterFromCacheJson(json)).toList();
          if (kDebugMode) {
            print(
                '✅ CacheDataService: Loaded ${chapters.length} chapters from cache for module $moduleId');
          }
          return CacheResult.fromCache(chapters);
        }
      }

      // Fetch from API
      if (kDebugMode) {
        print(
            '🔄 CacheDataService: Fetching chapters from API for module $moduleId...');
      }
      final response =
          await _moduleContentApiService.getModuleChapters(moduleId);
      if (response.success && response.data.isNotEmpty) {
        // Save to cache using toJson
        await _cacheService.saveChaptersCache(
          moduleId,
          response.data.map((c) => c.toJson()).toList(),
        );
        if (kDebugMode) {
          print(
              '✅ CacheDataService: Chapters cached (${response.data.length} chapters) for module $moduleId');
        }
        return CacheResult.fromApi(response.data);
      }

      return CacheResult.failure(response.message);
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ CacheDataService: Error getting chapters for module $moduleId: $e');
      }
      return CacheResult.failure(e.toString());
    }
  }

  /// Helper to deserialize chapter from cache JSON
  /// This handles the difference between API JSON (title) and cache JSON (name)
  ModuleChapter _chapterFromCacheJson(Map<String, dynamic> json) {
    return ModuleChapter(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'],
      theory: json['theory'],
      moduleId: json['module_id'] ?? '',
      order: json['order'] ?? 0,
      logo: json['logo'],
      questionCount: json['question_count'] ?? json['content_count'] ?? 0,
      status: json['status'] ?? 'not_started',
      isEnabled: json['is_enabled'] ?? true,
      isImportant: json['is_important'] ?? false,
      hasHots: json['has_hots'] ?? false,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      currentQuestionId: json['current_question_id']?.toString(),
      userStatus: json['user_status'],
      userPercentage: (json['user_percentage'] ?? 0.0).toDouble(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      lastAccessed: json['last_accessed'] != null
          ? DateTime.parse(json['last_accessed'])
          : null,
    );
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Update a specific module's status and percentage in the local storage cache
  /// This ensures the cache stays in sync with in-memory updates
  Future<bool> updateModuleInCache(
    String subjectId,
    String moduleId,
    ModuleStatus newStatus,
    double newPercentage,
  ) async {
    try {
      // Get current cached modules for this subject
      final cachedData = await _cacheService.getModulesCache(subjectId);
      if (cachedData == null) {
        if (kDebugMode) {
          print(
              '⚠️ CacheDataService: No cached modules found for subject $subjectId');
        }
        return false;
      }

      // Find and update the specific module
      bool found = false;
      final updatedModules = cachedData.map((moduleJson) {
        if (moduleJson['id']?.toString() == moduleId) {
          found = true;
          return {
            ...moduleJson,
            'user_status': newStatus.value,
            'user_percentage': newPercentage,
          };
        }
        return moduleJson;
      }).toList();

      if (!found) {
        if (kDebugMode) {
          print(
              '⚠️ CacheDataService: Module $moduleId not found in cache for subject $subjectId');
        }
        return false;
      }

      // Save updated modules back to cache
      final success =
          await _cacheService.saveModulesCache(subjectId, updatedModules);

      if (kDebugMode) {
        print(
            '✅ CacheDataService: Updated module $moduleId in cache - status: ${newStatus.value}, percentage: $newPercentage%');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheDataService: Error updating module in cache: $e');
      }
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
  }

  /// Invalidate specific cache type
  Future<void> invalidateUserCache() async {
    await _cacheService.clearUserCache();
  }

  Future<void> invalidateSubjectsCache() async {
    await _cacheService.clearSubjectsCache();
  }

  Future<void> invalidateModulesCache(String subjectId) async {
    await _cacheService.clearModulesCache(subjectId);
  }

  Future<void> invalidateLeaderboardCache() async {
    await _cacheService.clearLeaderboardCache();
  }

  Future<void> invalidateMissionsCache({int? month, int? year}) async {
    await _cacheService.clearMissionsCache(month: month, year: year);
  }

  Future<void> invalidateChaptersCache(String moduleId) async {
    await _cacheService.clearChaptersCache(moduleId);
  }

  /// Refresh all data (clear cache and prefetch)
  Future<CachePrefetchStatus> refreshAllData() async {
    await clearAllCache();
    return prefetchAllData();
  }
}
