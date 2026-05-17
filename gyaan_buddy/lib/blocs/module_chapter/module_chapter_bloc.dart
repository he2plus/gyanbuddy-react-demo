import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/module_chapter_model.dart';
import '../../models/module_status.dart';
import '../../services/module_content_api_service.dart';
import '../../services/cache_data_service.dart';

// Events
abstract class ModuleChapterEvent extends Equatable {
  const ModuleChapterEvent();

  @override
  List<Object?> get props => [];
}

class LoadModuleChapters extends ModuleChapterEvent {
  final String moduleId;

  const LoadModuleChapters(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class RefreshModuleChapters extends ModuleChapterEvent {
  final String moduleId;

  const RefreshModuleChapters(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class UpdateChapterStatus extends ModuleChapterEvent {
  final String moduleId;
  final String chapterId;
  final ModuleStatus newStatus;
  final double newPercentage;

  const UpdateChapterStatus({
    required this.moduleId,
    required this.chapterId,
    required this.newStatus,
    required this.newPercentage,
  });

  @override
  List<Object?> get props => [moduleId, chapterId, newStatus, newPercentage];
}

class UpdateChapterCurrentQuestion extends ModuleChapterEvent {
  final String moduleId;
  final String chapterId;
  final String? currentQuestionId;

  const UpdateChapterCurrentQuestion({
    required this.moduleId,
    required this.chapterId,
    required this.currentQuestionId,
  });

  @override
  List<Object?> get props => [moduleId, chapterId, currentQuestionId];
}

// States
abstract class ModuleChapterState extends Equatable {
  const ModuleChapterState();

  @override
  List<Object?> get props => [];
}

class ModuleChapterInitial extends ModuleChapterState {}

class ModuleChapterLoading extends ModuleChapterState {
  final String moduleId;

  const ModuleChapterLoading(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class ModuleChaptersLoaded extends ModuleChapterState {
  final String moduleId;
  final List<ModuleChapter> chapters;

  const ModuleChaptersLoaded({
    required this.moduleId,
    required this.chapters,
  });

  @override
  List<Object?> get props => [moduleId, chapters];
}

class ModuleChapterError extends ModuleChapterState {
  final String message;

  const ModuleChapterError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ModuleChapterBloc extends Bloc<ModuleChapterEvent, ModuleChapterState> {
  final ModuleContentApiService _moduleContentApiService;
  
  // In-memory cache for chapters
  final Map<String, List<ModuleChapter>> _cachedChapters = {};

  ModuleChapterBloc(this._moduleContentApiService) : super(ModuleChapterInitial()) {
    on<LoadModuleChapters>(_onLoadModuleChapters);
    on<RefreshModuleChapters>(_onRefreshModuleChapters);
    on<UpdateChapterStatus>(_onUpdateChapterStatus);
    on<UpdateChapterCurrentQuestion>(_onUpdateChapterCurrentQuestion);
  }

  Future<void> _onLoadModuleChapters(
    LoadModuleChapters event,
    Emitter<ModuleChapterState> emit,
  ) async {
    final moduleId = event.moduleId;
    print('ModuleChapterBloc: Loading chapters for module: $moduleId');
    
    // 1. Check in-memory cache first
    if (_cachedChapters.containsKey(moduleId)) {
      print('ModuleChapterBloc: Using in-memory cached chapters for module: $moduleId');
      emit(ModuleChaptersLoaded(
        moduleId: moduleId,
        chapters: _cachedChapters[moduleId]!,
      ));
      await _refreshModuleChaptersQuietly(moduleId, emit);
      return;
    }

    // 2. Try to get from CacheDataService first (local storage cache)
    try {
      final cacheResult = await CacheDataService.instance.getChapters(moduleId);
      
      if (cacheResult.success && cacheResult.data != null) {
        print('ModuleChapterBloc: Loaded ${cacheResult.data!.length} chapters from ${cacheResult.fromCache ? "cache" : "API"} for module: $moduleId');
        // Cache in memory
        _cachedChapters[moduleId] = cacheResult.data!;
        
        emit(ModuleChaptersLoaded(
          moduleId: moduleId,
          chapters: cacheResult.data!,
        ));
        if (cacheResult.fromCache) {
          await _refreshModuleChaptersQuietly(moduleId, emit);
        }
      } else {
        // Only emit loading if we have no cache at all
        print('ModuleChapterBloc: No cache found, emitting loading state for module: $moduleId');
        emit(ModuleChapterLoading(moduleId));
        
        // Try direct API call as fallback
        final response = await _moduleContentApiService.getModuleChapters(moduleId);
        
        if (response.success) {
          print('ModuleChapterBloc: Successfully loaded ${response.data.length} chapters from API for module: $moduleId');
          _cachedChapters[moduleId] = response.data;
          
          emit(ModuleChaptersLoaded(
            moduleId: moduleId,
            chapters: response.data,
          ));
        } else {
          print('ModuleChapterBloc: Error loading chapters: ${response.message}');
          emit(ModuleChapterError(response.message));
        }
      }
    } catch (e) {
      print('ModuleChapterBloc: Exception loading chapters: $e');
      emit(ModuleChapterError(e.toString()));
    }
  }

  Future<void> _refreshModuleChaptersQuietly(
    String moduleId,
    Emitter<ModuleChapterState> emit,
  ) async {
    try {
      final cacheResult = await CacheDataService.instance.getChapters(
        moduleId,
        forceRefresh: true,
      );
      if (cacheResult.success && cacheResult.data != null) {
        _cachedChapters[moduleId] = cacheResult.data!;
        emit(ModuleChaptersLoaded(
          moduleId: moduleId,
          chapters: cacheResult.data!,
        ));
        print('ModuleChapterBloc: Quietly refreshed chapters for module: $moduleId');
      }
    } catch (e) {
      print('ModuleChapterBloc: Quiet chapter refresh failed for module $moduleId: $e');
    }
  }

  Future<void> _onRefreshModuleChapters(
    RefreshModuleChapters event,
    Emitter<ModuleChapterState> emit,
  ) async {
    final moduleId = event.moduleId;
    print('ModuleChapterBloc: Refreshing chapters for module: $moduleId');
    
    // Clear in-memory cache for this module
    _cachedChapters.remove(moduleId);
    
    // Clear local storage cache
    await CacheDataService.instance.invalidateChaptersCache(moduleId);
    
    print('ModuleChapterBloc: Emitting loading state for refresh of module: $moduleId');
    emit(ModuleChapterLoading(moduleId));

    try {
      // Force refresh from API
      final cacheResult = await CacheDataService.instance.getChapters(moduleId, forceRefresh: true);
      
      if (cacheResult.success && cacheResult.data != null) {
        print('ModuleChapterBloc: Successfully refreshed ${cacheResult.data!.length} chapters for module: $moduleId');
        // Cache the fresh chapters in memory
        _cachedChapters[moduleId] = cacheResult.data!;
        
        emit(ModuleChaptersLoaded(
          moduleId: moduleId,
          chapters: cacheResult.data!,
        ));
      } else {
        print('ModuleChapterBloc: Error refreshing chapters: ${cacheResult.error}');
        emit(ModuleChapterError(cacheResult.error ?? 'Failed to refresh chapters'));
      }
    } catch (e) {
      print('ModuleChapterBloc: Exception refreshing chapters: $e');
      emit(ModuleChapterError(e.toString()));
    }
  }

  // Helper getters
  List<ModuleChapter> getCachedChapters(String moduleId) {
    return _cachedChapters[moduleId] ?? [];
  }

  bool hasCachedChapters(String moduleId) {
    return _cachedChapters.containsKey(moduleId);
  }

  List<ModuleChapter> getSortedChapters(String moduleId) {
    final chapters = _cachedChapters[moduleId] ?? [];
    return List.from(chapters)..sort((a, b) => a.order.compareTo(b.order));
  }

  List<ModuleChapter> getEnabledChapters(String moduleId) {
    final chapters = _cachedChapters[moduleId] ?? [];
    return chapters.where((chapter) => chapter.isEnabled).toList();
  }

  List<ModuleChapter> getChaptersByStatus(String moduleId, String status) {
    final chapters = _cachedChapters[moduleId] ?? [];
    return chapters.where((chapter) => chapter.userStatus == status).toList();
  }

  // Calculate module status and percentage from chapters
  Map<String, dynamic> calculateModuleStatus(String moduleId) {
    final chapters = _cachedChapters[moduleId] ?? [];
    if (chapters.isEmpty) {
      return {
        'status': ModuleStatus.notStarted,
        'percentage': 0.0,
      };
    }

    // Filter enabled chapters only
    final enabledChapters = chapters.where((chapter) => chapter.isEnabled).toList();
    if (enabledChapters.isEmpty) {
      return {
        'status': ModuleStatus.notStarted,
        'percentage': 0.0,
      };
    }

    // Calculate average percentage
    double totalPercentage = 0.0;
    int completedCount = 0;
    int inProgressCount = 0;
    int notStartedCount = 0;

    for (final chapter in enabledChapters) {
      totalPercentage += chapter.userPercentage;
      
      if (chapter.userStatus == ModuleChapter.statusCompleted) {
        completedCount++;
      } else if (chapter.userStatus == ModuleChapter.statusInProgress) {
        inProgressCount++;
      } else {
        notStartedCount++;
      }
    }

    final averagePercentage = totalPercentage / enabledChapters.length;
    
    // Determine status
    ModuleStatus moduleStatus;
    if (completedCount == enabledChapters.length) {
      moduleStatus = ModuleStatus.completed;
    } else if (completedCount > 0 || inProgressCount > 0) {
      moduleStatus = ModuleStatus.inProgress;
    } else {
      moduleStatus = ModuleStatus.notStarted;
    }

    return {
      'status': moduleStatus,
      'percentage': averagePercentage,
    };
  }

  // Update chapter status after content completion
  void _onUpdateChapterStatus(
    UpdateChapterStatus event,
    Emitter<ModuleChapterState> emit,
  ) async {
    print('🔵 ModuleChapterBloc: _onUpdateChapterStatus called');
    final moduleId = event.moduleId;
    final chapterId = event.chapterId;
    
    print('🔵 ModuleChapterBloc: Looking for module $moduleId in cache');
    print('🔵 ModuleChapterBloc: Available modules: ${_cachedChapters.keys.toList()}');
    
    // Check if we have cached chapters for this module
    if (_cachedChapters.containsKey(moduleId)) {
      print('🔵 ModuleChapterBloc: Found module $moduleId with ${_cachedChapters[moduleId]!.length} chapters');
      final chapters = List<ModuleChapter>.from(_cachedChapters[moduleId]!);
      
      // Find and update the specific chapter
      final chapterIndex = chapters.indexWhere((chapter) => chapter.id == chapterId);
      print('🔵 ModuleChapterBloc: Looking for chapter $chapterId, found at index $chapterIndex');
      
      if (chapterIndex != -1) {
        print('🔵 ModuleChapterBloc: Old chapter status: ${chapters[chapterIndex].userStatus}, percentage: ${chapters[chapterIndex].userPercentage}');
        
        // Update the chapter status and percentage
        final updatedChapter = chapters[chapterIndex].copyWith(
          userStatus: event.newStatus.value,
          userPercentage: event.newPercentage,
        );
        
        print('🔵 ModuleChapterBloc: New chapter status: ${updatedChapter.userStatus}, percentage: ${updatedChapter.userPercentage}');
        
        chapters[chapterIndex] = updatedChapter;
        _cachedChapters[moduleId] = chapters;
        
        // Emit updated state
        print('🔵 ModuleChapterBloc: Emitting ModuleChaptersLoaded state');
        emit(ModuleChaptersLoaded(
          moduleId: moduleId,
          chapters: chapters,
        ));
        
        print('🔵 ModuleChapterBloc: Successfully updated chapter $chapterId status to ${event.newStatus} with ${event.newPercentage}%');
      } else {
        print('🔵 ModuleChapterBloc: Chapter $chapterId not found in module $moduleId');
      }
    } else {
      print('🔵 ModuleChapterBloc: Module $moduleId not found in cache');
    }
  }

  // Update chapter current question ID
  void _onUpdateChapterCurrentQuestion(
    UpdateChapterCurrentQuestion event,
    Emitter<ModuleChapterState> emit,
  ) {
    print('🔵 ModuleChapterBloc: _onUpdateChapterCurrentQuestion called');
    final moduleId = event.moduleId;
    final chapterId = event.chapterId;
    final currentQuestionId = event.currentQuestionId;
    
    print('🔵 ModuleChapterBloc: Updating currentQuestionId for chapter $chapterId to $currentQuestionId');
    
    // Check if we have cached chapters for this module
    if (_cachedChapters.containsKey(moduleId)) {
      final chapters = List<ModuleChapter>.from(_cachedChapters[moduleId]!);
      
      // Find and update the specific chapter
      final chapterIndex = chapters.indexWhere((chapter) => chapter.id == chapterId);
      
      if (chapterIndex != -1) {
        print('🔵 ModuleChapterBloc: Found chapter $chapterId at index $chapterIndex');
        print('🔵 ModuleChapterBloc: Old currentQuestionId: ${chapters[chapterIndex].currentQuestionId}');
        
        // Update the chapter currentQuestionId
        final updatedChapter = chapters[chapterIndex].copyWith(
          currentQuestionId: currentQuestionId,
        );
        
        print('🔵 ModuleChapterBloc: New currentQuestionId: ${updatedChapter.currentQuestionId}');
        
        chapters[chapterIndex] = updatedChapter;
        _cachedChapters[moduleId] = chapters;
        
        // Emit updated state
        emit(ModuleChaptersLoaded(
          moduleId: moduleId,
          chapters: chapters,
        ));
        
        print('🔵 ModuleChapterBloc: Successfully updated chapter $chapterId currentQuestionId to $currentQuestionId');
      } else {
        print('🔵 ModuleChapterBloc: Chapter $chapterId not found in module $moduleId');
      }
    } else {
      print('🔵 ModuleChapterBloc: Module $moduleId not found in cache');
    }
  }
}
