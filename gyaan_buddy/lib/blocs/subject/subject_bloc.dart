import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/subject_model.dart';
import '../../models/module_model.dart';
import '../../models/module_status.dart';
import '../../services/subject_api_service.dart';
import '../../services/cache_data_service.dart';

// Events
abstract class SubjectEvent extends Equatable {
  const SubjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjects extends SubjectEvent {
  const LoadSubjects();
}

class LoadSubjectById extends SubjectEvent {
  final String id;

  const LoadSubjectById(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshSubjects extends SubjectEvent {
  const RefreshSubjects();
}

class LoadSubjectModules extends SubjectEvent {
  final String subjectId;

  const LoadSubjectModules(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class RefreshSubjectModules extends SubjectEvent {
  final String subjectId;

  const RefreshSubjectModules(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class UpdateModuleStatus extends SubjectEvent {
  final String subjectId;
  final String moduleId;
  final ModuleStatus newStatus;
  final double newPercentage;

  const UpdateModuleStatus({
    required this.subjectId,
    required this.moduleId,
    required this.newStatus,
    required this.newPercentage,
  });

  @override
  List<Object?> get props => [subjectId, moduleId, newStatus, newPercentage];
}

// States
abstract class SubjectState extends Equatable {
  const SubjectState();

  @override
  List<Object?> get props => [];
}

class SubjectInitial extends SubjectState {}

class SubjectLoading extends SubjectState {}

class SubjectsLoaded extends SubjectState {
  final List<Subject> subjects;

  const SubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}

class SubjectLoaded extends SubjectState {
  final Subject subject;

  const SubjectLoaded(this.subject);

  @override
  List<Object?> get props => [subject];
}

class SubjectError extends SubjectState {
  final String message;

  const SubjectError(this.message);

  @override
  List<Object?> get props => [message];
}

class ModulesLoading extends SubjectState {
  final String subjectId;

  const ModulesLoading(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class ModulesLoaded extends SubjectState {
  final String subjectId;
  final List<Module> modules;

  const ModulesLoaded(this.subjectId, this.modules);

  @override
  List<Object?> get props => [subjectId, modules];
}

class ModulesError extends SubjectState {
  final String subjectId;
  final String message;

  const ModulesError(this.subjectId, this.message);

  @override
  List<Object?> get props => [subjectId, message];
}

class SubjectBloc extends Bloc<SubjectEvent, SubjectState> {
  final SubjectApiService _subjectApiService;
  List<Subject> _cachedSubjects = [];
  Map<String, List<Module>> _cachedModules = {};
  bool _fetchedOne = false;
  bool _isRefreshingSubjects = false;

  SubjectBloc({SubjectApiService? subjectApiService})
      : _subjectApiService = subjectApiService ?? SubjectApiService(),
        super(SubjectInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<LoadSubjectById>(_onLoadSubjectById);
    on<RefreshSubjects>(_onRefreshSubjects);
    on<LoadSubjectModules>(_onLoadSubjectModules);
    on<RefreshSubjectModules>(_onRefreshSubjectModules);
    on<UpdateModuleStatus>(_onUpdateModuleStatus);
  }

  void _onLoadSubjects(LoadSubjects event, Emitter<SubjectState> emit) async {
    // If we already have cached subjects in bloc memory, return them (no loading state)
    if (_fetchedOne && _cachedSubjects.isNotEmpty) {
      emit(SubjectsLoaded(_cachedSubjects));
      await _refreshSubjectsQuietly(emit);
      return;
    }

    try {
      // Try to get from CacheDataService first (local storage cache)
      // Don't emit loading if we have local cache
      final cacheResult = await CacheDataService.instance.getSubjects();

      if (cacheResult.success && cacheResult.data != null) {
        _cachedSubjects = cacheResult.data!;
        _fetchedOne = true;
        print(
            '🔵 SubjectBloc: Loaded ${_cachedSubjects.length} subjects from ${cacheResult.fromCache ? "cache" : "API"}');
        emit(SubjectsLoaded(_cachedSubjects));
        if (cacheResult.fromCache) {
          await _refreshSubjectsQuietly(emit);
        }
      } else {
        // Only emit loading if we need to show skeleton (no cache at all)
        emit(SubjectLoading());

        // Try direct API call as fallback
        final response = await _subjectApiService.getAllSubjects();
        if (response.success && response.data != null) {
          _cachedSubjects = response.data!;
          _fetchedOne = true;
          emit(SubjectsLoaded(_cachedSubjects));
        } else {
          emit(SubjectError(response.message));
        }
      }
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  Future<void> _refreshSubjectsQuietly(Emitter<SubjectState> emit) async {
    if (_isRefreshingSubjects) return;
    _isRefreshingSubjects = true;
    try {
      final cacheResult =
          await CacheDataService.instance.getSubjects(forceRefresh: true);
      if (cacheResult.success && cacheResult.data != null) {
        _cachedSubjects = cacheResult.data!;
        _fetchedOne = true;
        emit(SubjectsLoaded(_cachedSubjects));
        print('🔵 SubjectBloc: Quietly refreshed subjects from API');
      }
    } catch (e) {
      print('🔵 SubjectBloc: Quiet subject refresh failed: $e');
    } finally {
      _isRefreshingSubjects = false;
    }
  }

  void _onLoadSubjectById(
      LoadSubjectById event, Emitter<SubjectState> emit) async {
    // First try to find the subject in cached data
    if (_fetchedOne && _cachedSubjects.isNotEmpty) {
      try {
        final cachedSubject = _cachedSubjects.firstWhere(
          (subject) => subject.id == event.id,
        );
        emit(SubjectLoaded(cachedSubject));
        return;
      } catch (e) {
        // Subject not found in cache, continue to API call
      }
    }

    emit(SubjectLoading());

    try {
      final response = await _subjectApiService.getSubjectById(event.id);

      if (response.success && response.data != null) {
        emit(SubjectLoaded(response.data!));
      } else {
        emit(SubjectError(response.message));
      }
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  void _onRefreshSubjects(
      RefreshSubjects event, Emitter<SubjectState> emit) async {
    // Reset the fetched flag and clear local storage cache to force a fresh API call
    _fetchedOne = false;
    _cachedSubjects = [];
    await CacheDataService.instance.invalidateSubjectsCache();
    add(const LoadSubjects());
  }

  void _onLoadSubjectModules(
      LoadSubjectModules event, Emitter<SubjectState> emit) async {
    print(
        '🔵 SubjectBloc: _onLoadSubjectModules called for subject ${event.subjectId}');

    // Check if we have cached modules in bloc memory for this subject (no loading state)
    if (_cachedModules.containsKey(event.subjectId)) {
      print(
          '🔵 SubjectBloc: Using bloc-cached modules for subject ${event.subjectId}');
      emit(ModulesLoaded(event.subjectId, _cachedModules[event.subjectId]!));
      await _refreshSubjectModulesQuietly(event.subjectId, emit);
      return;
    }

    try {
      // Try to get from CacheDataService first (local storage cache)
      // Don't emit loading if we have local cache
      final cacheResult =
          await CacheDataService.instance.getModules(event.subjectId);

      if (cacheResult.success && cacheResult.data != null) {
        print(
            '🔵 SubjectBloc: Loaded ${cacheResult.data!.length} modules from ${cacheResult.fromCache ? "cache" : "API"} for subject ${event.subjectId}');
        _cachedModules[event.subjectId] = cacheResult.data!;
        emit(ModulesLoaded(event.subjectId, cacheResult.data!));
        if (cacheResult.fromCache) {
          await _refreshSubjectModulesQuietly(event.subjectId, emit);
        }
      } else {
        // Only emit loading if we have no cache at all
        emit(ModulesLoading(event.subjectId));

        // Try direct API call as fallback
        final response =
            await _subjectApiService.getSubjectModules(event.subjectId);
        if (response.success && response.data != null) {
          _cachedModules[event.subjectId] = response.data!;
          emit(ModulesLoaded(event.subjectId, response.data!));
        } else {
          emit(ModulesError(event.subjectId, response.message));
        }
        return;
      }
    } catch (e) {
      print('🔵 SubjectBloc: Exception for subject ${event.subjectId}: $e');
      emit(ModulesError(event.subjectId, e.toString()));
    }
  }

  Future<void> _refreshSubjectModulesQuietly(
    String subjectId,
    Emitter<SubjectState> emit,
  ) async {
    try {
      final cacheResult = await CacheDataService.instance.getModules(
        subjectId,
        forceRefresh: true,
      );
      if (cacheResult.success && cacheResult.data != null) {
        _cachedModules[subjectId] = cacheResult.data!;
        emit(ModulesLoaded(subjectId, cacheResult.data!));
        print(
            '🔵 SubjectBloc: Quietly refreshed modules for subject $subjectId');
      }
    } catch (e) {
      print(
          '🔵 SubjectBloc: Quiet module refresh failed for subject $subjectId: $e');
    }
  }

  void _onRefreshSubjectModules(
      RefreshSubjectModules event, Emitter<SubjectState> emit) async {
    print(
        '🔵 SubjectBloc: _onRefreshSubjectModules called for subject ${event.subjectId}');

    // Keep showing cached modules while refreshing in background
    final cachedModules = _cachedModules[event.subjectId];
    final hasCachedModules = cachedModules != null;

    if (hasCachedModules) {
      print('🔵 SubjectBloc: Keeping cached modules visible during refresh');
      // Keep the cached modules in memory so UI continues to show them
      // Don't remove from _cachedModules yet - we'll update it after API call
    }

    // Clear local storage cache (but keep in-memory cache for now)
    await CacheDataService.instance.invalidateModulesCache(event.subjectId);
    print(
        '🔵 SubjectBloc: Cleared local storage cache for subject ${event.subjectId}');

    // Fetch fresh data from API in background using CacheDataService (which handles caching)
    try {
      final cacheResult = await CacheDataService.instance.getModules(
        event.subjectId,
        forceRefresh: true,
      );

      if (cacheResult.success && cacheResult.data != null) {
        // Update cache with fresh data
        _cachedModules[event.subjectId] = cacheResult.data!;
        // Emit updated modules (this will update the UI with fresh data)
        emit(ModulesLoaded(event.subjectId, cacheResult.data!));
        print(
            '🔵 SubjectBloc: Refreshed modules from API for subject ${event.subjectId}');
      } else {
        // If API call fails, keep showing cached modules if available
        if (hasCachedModules) {
          // Keep the cached modules (they're still in _cachedModules)
          emit(ModulesLoaded(event.subjectId, cachedModules));
          print(
              '🔵 SubjectBloc: API call failed, keeping cached modules visible');
        } else {
          // No cached modules, show error
          emit(ModulesError(event.subjectId,
              cacheResult.error ?? 'Failed to refresh modules'));
        }
      }
    } catch (e) {
      print('🔵 SubjectBloc: Exception refreshing modules: $e');
      // If exception, keep showing cached modules if available
      if (hasCachedModules) {
        // Keep the cached modules (they're still in _cachedModules)
        emit(ModulesLoaded(event.subjectId, cachedModules));
        print(
            '🔵 SubjectBloc: Exception occurred, keeping cached modules visible');
      } else {
        emit(ModulesError(event.subjectId, e.toString()));
      }
    }
  }

  // Method to clear cache manually
  void clearCache() {
    _fetchedOne = false;
    _cachedSubjects = [];
    _cachedModules.clear();
  }

  // Getter to check if subjects have been fetched
  bool get hasFetchedSubjects => _fetchedOne && _cachedSubjects.isNotEmpty;

  // Getter to access cached subjects
  List<Subject> get cachedSubjects => List.unmodifiable(_cachedSubjects);

  // Getter to access cached modules for a specific subject
  List<Module> getCachedModules(String subjectId) {
    return _cachedModules[subjectId] ?? [];
  }

  // Check if modules are cached for a specific subject
  bool hasCachedModules(String subjectId) {
    return _cachedModules.containsKey(subjectId);
  }

  // Update module status after content completion
  void _onUpdateModuleStatus(
    UpdateModuleStatus event,
    Emitter<SubjectState> emit,
  ) async {
    print('🔵 SubjectBloc: _onUpdateModuleStatus called');
    final subjectId = event.subjectId;
    final moduleId = event.moduleId;

    print('🔵 SubjectBloc: Looking for subject $subjectId in cache');
    print(
        '🔵 SubjectBloc: Available subjects: ${_cachedModules.keys.toList()}');

    // If subject not in memory cache, try to load it first
    if (!_cachedModules.containsKey(subjectId)) {
      print(
          '🔵 SubjectBloc: Subject $subjectId not in memory, loading from cache/API...');
      try {
        final cacheResult =
            await CacheDataService.instance.getModules(subjectId);
        if (cacheResult.success && cacheResult.data != null) {
          _cachedModules[subjectId] = cacheResult.data!;
          print(
              '🔵 SubjectBloc: Loaded ${cacheResult.data!.length} modules into memory cache');
        }
      } catch (e) {
        print('🔵 SubjectBloc: Error loading modules: $e');
      }
    }

    // Check if we have cached modules for this subject
    if (_cachedModules.containsKey(subjectId)) {
      print(
          '🔵 SubjectBloc: Found subject $subjectId with ${_cachedModules[subjectId]!.length} modules');
      final modules = List<Module>.from(_cachedModules[subjectId]!);

      // Find and update the specific module
      final moduleIndex = modules.indexWhere((module) => module.id == moduleId);
      print(
          '🔵 SubjectBloc: Looking for module $moduleId, found at index $moduleIndex');

      if (moduleIndex != -1) {
        print(
            '🔵 SubjectBloc: Old module status: ${modules[moduleIndex].userStatus}, percentage: ${modules[moduleIndex].userPercentage}');

        // Update the module status and percentage
        final updatedModule = modules[moduleIndex].copyWith(
          userStatus: event.newStatus,
          userPercentage: event.newPercentage,
        );

        print(
            '🔵 SubjectBloc: New module status: ${updatedModule.userStatus}, percentage: ${updatedModule.userPercentage}');

        modules[moduleIndex] = updatedModule;
        _cachedModules[subjectId] = modules;

        // Also update local storage cache for persistence
        try {
          await CacheDataService.instance.updateModuleInCache(
            subjectId,
            moduleId,
            event.newStatus,
            event.newPercentage,
          );
          print('🔵 SubjectBloc: Local storage cache updated');
        } catch (e) {
          print('🔵 SubjectBloc: Error updating local cache: $e');
        }

        // Emit updated state
        print('🔵 SubjectBloc: Emitting ModulesLoaded state');
        emit(ModulesLoaded(subjectId, modules));

        print(
            '🔵 SubjectBloc: Successfully updated module $moduleId status to ${event.newStatus} with ${event.newPercentage}%');
      } else {
        print(
            '🔵 SubjectBloc: Module $moduleId not found in subject $subjectId');
      }
    } else {
      print(
          '🔵 SubjectBloc: Subject $subjectId still not found in cache after load attempt');
    }
  }
}
