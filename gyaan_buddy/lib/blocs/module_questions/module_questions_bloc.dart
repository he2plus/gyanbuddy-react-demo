import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/module_content_item_model.dart';
import '../../models/module_questions_response.dart';
import '../../models/question_model.dart';
import '../../services/subject_api_service.dart';

// Events
abstract class ModuleQuestionsEvent extends Equatable {
  const ModuleQuestionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadModuleQuestions extends ModuleQuestionsEvent {
  final String chapterId;

  const LoadModuleQuestions(this.chapterId);

  @override
  List<Object?> get props => [chapterId];
}

class RefreshModuleQuestions extends ModuleQuestionsEvent {
  final String chapterId;

  const RefreshModuleQuestions(this.chapterId);

  @override
  List<Object?> get props => [chapterId];
}

class FilterQuestions extends ModuleQuestionsEvent {
  final String? contentType;
  final String? difficultyLevel;

  const FilterQuestions({
    this.contentType,
    this.difficultyLevel,
  });

  @override
  List<Object?> get props => [contentType, difficultyLevel];
}

class ClearFilters extends ModuleQuestionsEvent {
  const ClearFilters();
}

// States
abstract class ModuleQuestionsState extends Equatable {
  const ModuleQuestionsState();

  @override
  List<Object?> get props => [];
}

class ModuleQuestionsInitial extends ModuleQuestionsState {}

class ModuleQuestionsLoading extends ModuleQuestionsState {}

class ModuleQuestionsLoaded extends ModuleQuestionsState {
  final List<Question> questions;
  final String? activeFilter;
  final String? difficultyFilter;

  const ModuleQuestionsLoaded({
    required this.questions,
    this.activeFilter,
    this.difficultyFilter,
  });

  ModuleQuestionsLoaded copyWith({
    List<Question>? questions,
    String? activeFilter,
    String? difficultyFilter,
  }) {
    return ModuleQuestionsLoaded(
      questions: questions ?? this.questions,
      activeFilter: activeFilter ?? this.activeFilter,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
    );
  }

  // Get filtered questions based on active filters
  List<Question> get filteredQuestions {
    var filteredQuestions = questions;
    
    if (activeFilter != null && activeFilter!.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) => q.questionType.value == activeFilter).toList();
    }
    
    if (difficultyFilter != null && difficultyFilter!.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) => q.difficultyLevel.value == difficultyFilter).toList();
    }
    
    return filteredQuestions;
  }

  // Get available content types for filtering
  List<String> get availableContentTypes {
    final types = <String>{};
    for (final question in questions) {
      types.add(question.questionType.value);
    }
    return types.toList()..sort();
  }

  // Get available difficulty levels for filtering
  List<String> get availableDifficultyLevels {
    final levels = <String>{};
    for (final question in questions) {
      levels.add(question.difficultyLevel.value);
    }
    return levels.toList()..sort();
  }

  @override
  List<Object?> get props => [questions, activeFilter, difficultyFilter];
}

class ModuleQuestionsError extends ModuleQuestionsState {
  final String message;

  const ModuleQuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ModuleQuestionsBloc extends Bloc<ModuleQuestionsEvent, ModuleQuestionsState> {
  final SubjectApiService _subjectApiService;

  ModuleQuestionsBloc({
    SubjectApiService? subjectApiService,
  }) : _subjectApiService = subjectApiService ?? SubjectApiService(),
        super(ModuleQuestionsInitial()) {
    on<LoadModuleQuestions>(_onLoadModuleQuestions);
    on<RefreshModuleQuestions>(_onRefreshModuleQuestions);
    on<FilterQuestions>(_onFilterQuestions);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadModuleQuestions(
    LoadModuleQuestions event,
    Emitter<ModuleQuestionsState> emit,
  ) async {
    emit(ModuleQuestionsLoading());
    
    try {
      print('🔵 ModuleQuestionsBloc: Loading module questions for chapter: ${event.chapterId}');
      
      final response = await _subjectApiService.getModuleQuestions(event.chapterId);
      
      if (response.success && response.data != null) {
        print('🔵 ModuleQuestionsBloc: Successfully loaded module questions');
        emit(ModuleQuestionsLoaded(
          questions: response.data!,
        ));
      } else {
        print('🔵 ModuleQuestionsBloc: Failed to load module questions: ${response.message}');
        emit(ModuleQuestionsError(response.message));
      }
    } catch (e) {
      print('🔵 ModuleQuestionsBloc: Exception occurred: $e');
      emit(ModuleQuestionsError(e.toString()));
    }
  }

  Future<void> _onRefreshModuleQuestions(
    RefreshModuleQuestions event,
    Emitter<ModuleQuestionsState> emit,
  ) async {
    if (state is ModuleQuestionsLoaded) {
      final currentState = state as ModuleQuestionsLoaded;
      emit(ModuleQuestionsLoading());
      
      try {
        print('🔵 ModuleQuestionsBloc: Refreshing module questions for chapter: ${event.chapterId}');
        
        final response = await _subjectApiService.getModuleQuestions(event.chapterId);
        
        if (response.success && response.data != null) {
          print('🔵 ModuleQuestionsBloc: Successfully refreshed module questions');
          emit(ModuleQuestionsLoaded(
            questions: response.data!,
            activeFilter: currentState.activeFilter,
            difficultyFilter: currentState.difficultyFilter,
          ));
        } else {
          print('🔵 ModuleQuestionsBloc: Failed to refresh module questions: ${response.message}');
          emit(ModuleQuestionsError(response.message));
        }
      } catch (e) {
        print('🔵 ModuleQuestionsBloc: Exception occurred during refresh: $e');
        emit(ModuleQuestionsError(e.toString()));
      }
    }
  }

  void _onFilterQuestions(
    FilterQuestions event,
    Emitter<ModuleQuestionsState> emit,
  ) {
    if (state is ModuleQuestionsLoaded) {
      final currentState = state as ModuleQuestionsLoaded;
      
      emit(currentState.copyWith(
        activeFilter: event.contentType,
        difficultyFilter: event.difficultyLevel,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<ModuleQuestionsState> emit,
  ) {
    if (state is ModuleQuestionsLoaded) {
      final currentState = state as ModuleQuestionsLoaded;
      
      emit(currentState.copyWith(
        activeFilter: null,
        difficultyFilter: null,
      ));
    }
  }
}
