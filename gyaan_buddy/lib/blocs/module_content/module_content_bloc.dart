import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/module_content_model.dart';
import '../../models/question_model.dart';
import '../../services/module_content_api_service.dart';

// Events
abstract class ModuleContentEvent extends Equatable {
  const ModuleContentEvent();

  @override
  List<Object?> get props => [];
}

class LoadModuleContents extends ModuleContentEvent {
  final String moduleId;

  const LoadModuleContents(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class RefreshModuleContents extends ModuleContentEvent {
  final String moduleId;

  const RefreshModuleContents(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class LoadNextContent extends ModuleContentEvent {
  final String chapterId;
  final String? contentId;

  const LoadNextContent(this.chapterId, [this.contentId]);

  @override
  List<Object?> get props => [chapterId, contentId];
}

class RefreshNextContent extends ModuleContentEvent {
  final String chapterId;
  final String? contentId;

  const RefreshNextContent(this.chapterId, [this.contentId]);

  @override
  List<Object?> get props => [chapterId, contentId];
}

// States
abstract class ModuleContentState extends Equatable {
  const ModuleContentState();

  @override
  List<Object?> get props => [];
}

class ModuleContentInitial extends ModuleContentState {}

class ModuleContentLoading extends ModuleContentState {
  final String moduleId;

  const ModuleContentLoading(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class ModuleContentsLoaded extends ModuleContentState {
  final String moduleId;
  final List<ModuleContentItem> contents;

  const ModuleContentsLoaded(this.moduleId, this.contents);

  @override
  List<Object?> get props => [moduleId, contents];
}

class ModuleContentError extends ModuleContentState {
  final String moduleId;
  final String message;

  const ModuleContentError(this.moduleId, this.message);

  @override
  List<Object?> get props => [moduleId, message];
}

class NextContentLoading extends ModuleContentState {
  final String chapterId;

  const NextContentLoading(this.chapterId);

  @override
  List<Object?> get props => [chapterId];
}

class NextContentLoaded extends ModuleContentState {
  final String chapterId;
  final ModuleContentItem content;

  const NextContentLoaded(this.chapterId, this.content);

  @override
  List<Object?> get props => [chapterId, content];
}

class NextContentError extends ModuleContentState {
  final String chapterId;
  final String message;

  const NextContentError(this.chapterId, this.message);

  @override
  List<Object?> get props => [chapterId, message];
}

class NoNextContent extends ModuleContentState {
  final String chapterId;
  final String message;

  const NoNextContent(this.chapterId, this.message);

  @override
  List<Object?> get props => [chapterId, message];
}

class ModuleContentBloc extends Bloc<ModuleContentEvent, ModuleContentState> {
  final ModuleContentApiService _moduleContentApiService;
  Map<String, List<ModuleContentItem>> _cachedContents = {};
  Map<String, ModuleContentItem> _cachedNextContent = {};

  ModuleContentBloc({ModuleContentApiService? moduleContentApiService})
      : _moduleContentApiService = moduleContentApiService ?? ModuleContentApiService(),
        super(ModuleContentInitial()) {
    on<LoadModuleContents>(_onLoadModuleContents);
    on<RefreshModuleContents>(_onRefreshModuleContents);
    on<LoadNextContent>(_onLoadNextContent);
    on<RefreshNextContent>(_onRefreshNextContent);
  }

  void _onLoadModuleContents(LoadModuleContents event, Emitter<ModuleContentState> emit) async {
    // Check if we have cached contents for this module
    if (_cachedContents.containsKey(event.moduleId)) {
      emit(ModuleContentsLoaded(event.moduleId, _cachedContents[event.moduleId]!));
      return;
    }

    emit(ModuleContentLoading(event.moduleId));
    
    try {
      final response = await _moduleContentApiService.getModuleContents(event.moduleId);
      
      if (response.success) {
        _cachedContents[event.moduleId] = response.data;
        emit(ModuleContentsLoaded(event.moduleId, response.data));
      } else {
        emit(ModuleContentError(event.moduleId, response.message));
      }
    } catch (e) {
      emit(ModuleContentError(event.moduleId, e.toString()));
    }
  }

  void _onRefreshModuleContents(RefreshModuleContents event, Emitter<ModuleContentState> emit) async {
    // Remove cached contents for this module to force a fresh API call
    _cachedContents.remove(event.moduleId);
    
    emit(ModuleContentLoading(event.moduleId));
    
    try {
      final response = await _moduleContentApiService.getModuleContents(event.moduleId);
      
      if (response.success) {
        _cachedContents[event.moduleId] = response.data;
        emit(ModuleContentsLoaded(event.moduleId, response.data));
      } else {
        emit(ModuleContentError(event.moduleId, response.message));
      }
    } catch (e) {
      emit(ModuleContentError(event.moduleId, e.toString()));
    }
  }

  void _onLoadNextContent(LoadNextContent event, Emitter<ModuleContentState> emit) async {
    // Check if we have cached next content for this chapter and contentId combination
    final cacheKey = '${event.chapterId}_${event.contentId ?? 'initial'}';
    if (_cachedNextContent.containsKey(cacheKey)) {
      final cachedContent = _cachedNextContent[cacheKey];
      if (cachedContent != null) {
        print('🔵 BLoC: Using cached next content: ${cachedContent.contentTitle}');
        emit(NextContentLoaded(event.chapterId, cachedContent));
        return;
      }
    }
    
    emit(NextContentLoading(event.chapterId));
    
    try {
      print('🔵 BLoC: Calling API service...');
      final response = await _moduleContentApiService.getNextContent(event.chapterId, event.contentId);
      
      print('🔵 BLoC: API response received - success: ${response.success}, data length: ${response.data.length}, message: ${response.message}');
      
      if (response.success) {
        if (response.data.isNotEmpty) {
          final nextContent = response.data.first;
          _cachedNextContent[cacheKey] = nextContent;
          print('🔵 BLoC: Emitting NextContentLoaded state with content: ${nextContent.contentTitle}');
          emit(NextContentLoaded(event.chapterId, nextContent));
        } else {
          // This is a legitimate "no more content" scenario (user completed everything)
          print('🔵 BLoC: Emitting NoNextContent state - no more content available');
          print('🔵 BLoC: Chapter ID: ${event.chapterId}, Response message: ${response.message}');
          print('🔵 BLoC: Current state before emit: ${state.runtimeType}');
          emit(NoNextContent(event.chapterId, response.message));
          print('🔵 BLoC: NoNextContent state emitted for chapter: ${event.chapterId}');
        }
      } else {
        // This is an API error, not a legitimate "no more content" scenario
        print('🔵 BLoC: Emitting NextContentError state - API error: ${response.message}');
        emit(NextContentError(event.chapterId, response.message));
      }
    } catch (e) {
      print('🔵 BLoC: Error occurred: $e');
      emit(NextContentError(event.chapterId, e.toString()));
    }
  }

  void _onRefreshNextContent(RefreshNextContent event, Emitter<ModuleContentState> emit) async {
    // Remove cached next content for this chapter and contentId combination to force a fresh API call
    final cacheKey = '${event.chapterId}_${event.contentId ?? 'initial'}';
    _cachedNextContent.remove(cacheKey);
    
    emit(NextContentLoading(event.chapterId));
    
    try {
      final response = await _moduleContentApiService.getNextContent(event.chapterId, event.contentId);
      
      if (response.success) {
        if (response.data.isNotEmpty) {
          final nextContent = response.data.first;
          _cachedNextContent[cacheKey] = nextContent;
          emit(NextContentLoaded(event.chapterId, nextContent));
        } else {
          // This is a legitimate "no more content" scenario (user completed everything)
          print('🔵 BLoC: Refresh - Emitting NoNextContent state - no more content available');
          print('🔵 BLoC: Refresh - Chapter ID: ${event.chapterId}, Response message: ${response.message}');
          print('🔵 BLoC: Refresh - Current state before emit: ${state.runtimeType}');
          emit(NoNextContent(event.chapterId, response.message));
          print('🔵 BLoC: Refresh - NoNextContent state emitted for chapter: ${event.chapterId}');
        }
      } else {
        // This is an API error, not a legitimate "no more content" scenario
        emit(NextContentError(event.chapterId, response.message));
      }
    } catch (e) {
      emit(NextContentError(event.chapterId, e.toString()));
    }
  }

  // Method to clear cache manually
  void clearCache() {
    _cachedContents.clear();
  }

  // Getter to access cached contents for a specific module
  List<ModuleContentItem> getCachedContents(String moduleId) {
    return _cachedContents[moduleId] ?? [];
  }

  // Check if contents are cached for a specific module
  bool hasCachedContents(String moduleId) {
    return _cachedContents.containsKey(moduleId);
  }

  // Get theory contents only
  List<TheoryContent> getTheoryContents(String moduleId) {
    final contents = _cachedContents[moduleId] ?? [];
    return contents
        .where((item) => item.contentType == 'theory' && item.theory != null)
        .map((item) => item.theory!)
        .toList();
  }

  // Get question contents only
  List<Question> getQuestionContents(String moduleId) {
    final contents = _cachedContents[moduleId] ?? [];
    return contents
        .where((item) => item.contentType == 'question' && item.question != null)
        .map((item) => item.question!)
        .toList();
  }

  // Get sorted contents by order
  List<ModuleContentItem> getSortedContents(String moduleId) {
    final contents = _cachedContents[moduleId] ?? [];
    final sortedContents = List<ModuleContentItem>.from(contents);
    sortedContents.sort((a, b) => a.order.compareTo(b.order));
    return sortedContents;
  }

  // Get cached next content for a specific chapter and contentId combination
  ModuleContentItem? getCachedNextContent(String chapterId, [String? contentId]) {
    final cacheKey = '${chapterId}_${contentId ?? 'initial'}';
    return _cachedNextContent[cacheKey];
  }

  // Check if next content is cached for a specific chapter and contentId combination
  bool hasCachedNextContent(String chapterId, [String? contentId]) {
    final cacheKey = '${chapterId}_${contentId ?? 'initial'}';
    return _cachedNextContent.containsKey(cacheKey);
  }

  // Clear next content cache
  void clearNextContentCache() {
    _cachedNextContent.clear();
  }

  // Clear all caches
  void clearAllCaches() {
    _cachedContents.clear();
    _cachedNextContent.clear();
  }

  // Method to get next content after completing a specific content
  void getNextContentAfterCompletion(String chapterId, String completedContentId) {
    add(LoadNextContent(chapterId, completedContentId));
  }
}
