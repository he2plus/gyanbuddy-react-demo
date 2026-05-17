import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/user_test_model.dart';
import '../../services/user_test_api_service.dart';

// Events
abstract class UserTestEvent extends Equatable {
  const UserTestEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserTests extends UserTestEvent {
  final String? status;

  const LoadUserTests({this.status});

  @override
  List<Object?> get props => [status];
}

class RefreshUserTests extends UserTestEvent {
  const RefreshUserTests();
}

class LoadTestById extends UserTestEvent {
  final String testId;

  const LoadTestById(this.testId);

  @override
  List<Object?> get props => [testId];
}

class StartTest extends UserTestEvent {
  final String testId;

  const StartTest(this.testId);

  @override
  List<Object?> get props => [testId];
}

class CompleteTest extends UserTestEvent {
  final String testId;

  const CompleteTest(this.testId);

  @override
  List<Object?> get props => [testId];
}

class LoadTestQuestions extends UserTestEvent {
  final String testId;

  const LoadTestQuestions(this.testId);

  @override
  List<Object?> get props => [testId];
}

class CheckTestAnswer extends UserTestEvent {
  final String testId;
  final String questionId;
  final String answerId;
  final int tries;
  final bool isCorrect;

  const CheckTestAnswer({
    required this.testId,
    required this.questionId,
    required this.answerId,
    required this.tries,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [testId, questionId, answerId, tries, isCorrect];
}

// States
abstract class UserTestState extends Equatable {
  const UserTestState();

  @override
  List<Object?> get props => [];
}

class UserTestInitial extends UserTestState {}

class UserTestLoading extends UserTestState {}

class UserTestsLoaded extends UserTestState {
  final List<UserTest> tests;
  final Map<String?, List<UserTest>> testsBySubject;
  final int pendingCount;

  const UserTestsLoaded({
    required this.tests,
    required this.testsBySubject,
    required this.pendingCount,
  });

  @override
  List<Object?> get props => [tests, testsBySubject, pendingCount];
}

class UserTestLoaded extends UserTestState {
  final UserTest test;

  const UserTestLoaded(this.test);

  @override
  List<Object?> get props => [test];
}

class UserTestQuestionsLoaded extends UserTestState {
  final String testId;
  final List<TestQuestion> questions;

  const UserTestQuestionsLoaded({
    required this.testId,
    required this.questions,
  });

  @override
  List<Object?> get props => [testId, questions];
}

class UserTestAnswerChecked extends UserTestState {
  final CheckAnswerResponse response;

  const UserTestAnswerChecked(this.response);

  @override
  List<Object?> get props => [response];
}

class UserTestError extends UserTestState {
  final String message;

  const UserTestError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class UserTestBloc extends Bloc<UserTestEvent, UserTestState> {
  final UserTestApiService _apiService = UserTestApiService();
  
  // Cached data
  List<UserTest> _cachedTests = [];
  Map<String?, List<UserTest>> _testsBySubject = {};

  UserTestBloc() : super(UserTestInitial()) {
    on<LoadUserTests>(_onLoadUserTests);
    on<RefreshUserTests>(_onRefreshUserTests);
    on<LoadTestById>(_onLoadTestById);
    on<StartTest>(_onStartTest);
    on<CompleteTest>(_onCompleteTest);
    on<LoadTestQuestions>(_onLoadTestQuestions);
    on<CheckTestAnswer>(_onCheckTestAnswer);
  }

  /// Get cached tests
  List<UserTest> get cachedTests => _cachedTests;
  
  /// Get tests grouped by subject
  Map<String?, List<UserTest>> get testsBySubject => _testsBySubject;
  
  /// Get count of pending tests (not started or in progress)
  int get pendingTestCount => _cachedTests
      .where((t) => !t.isCompleted)
      .length;
  
  /// Check if there are any tests
  bool get hasTests => _cachedTests.isNotEmpty;

  Future<void> _onLoadUserTests(
    LoadUserTests event,
    Emitter<UserTestState> emit,
  ) async {
    emit(UserTestLoading());
    
    try {
      final response = await _apiService.getMyTests(status: event.status);
      
      if (response.success && response.data != null) {
        _cachedTests = response.data!;
        _groupTestsBySubject();
        
        emit(UserTestsLoaded(
          tests: _cachedTests,
          testsBySubject: _testsBySubject,
          pendingCount: pendingTestCount,
        ));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  Future<void> _onRefreshUserTests(
    RefreshUserTests event,
    Emitter<UserTestState> emit,
  ) async {
    // Don't show loading state for refresh
    try {
      final response = await _apiService.getMyTests();
      
      if (response.success && response.data != null) {
        _cachedTests = response.data!;
        _groupTestsBySubject();
        
        emit(UserTestsLoaded(
          tests: _cachedTests,
          testsBySubject: _testsBySubject,
          pendingCount: pendingTestCount,
        ));
      }
    } catch (e) {
      // Silently fail on refresh
      print('Error refreshing tests: $e');
    }
  }

  Future<void> _onLoadTestById(
    LoadTestById event,
    Emitter<UserTestState> emit,
  ) async {
    emit(UserTestLoading());
    
    try {
      final response = await _apiService.getTestById(event.testId);
      
      if (response.success && response.data != null) {
        emit(UserTestLoaded(response.data!));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  Future<void> _onStartTest(
    StartTest event,
    Emitter<UserTestState> emit,
  ) async {
    emit(UserTestLoading());
    
    try {
      final response = await _apiService.startTest(event.testId);
      
      if (response.success && response.data != null) {
        // Update cached test
        _updateCachedTest(response.data!);
        
        emit(UserTestLoaded(response.data!));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  Future<void> _onCompleteTest(
    CompleteTest event,
    Emitter<UserTestState> emit,
  ) async {
    emit(UserTestLoading());
    
    try {
      final response = await _apiService.completeTest(event.testId);
      
      if (response.success && response.data != null) {
        // Update cached test
        _updateCachedTest(response.data!);
        
        emit(UserTestLoaded(response.data!));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  Future<void> _onLoadTestQuestions(
    LoadTestQuestions event,
    Emitter<UserTestState> emit,
  ) async {
    emit(UserTestLoading());
    
    try {
      final response = await _apiService.getTestQuestions(event.testId);
      
      if (response.success && response.data != null) {
        emit(UserTestQuestionsLoaded(
          testId: event.testId,
          questions: response.data!,
        ));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  Future<void> _onCheckTestAnswer(
    CheckTestAnswer event,
    Emitter<UserTestState> emit,
  ) async {
    try {
      final response = await _apiService.checkAnswer(
        testId: event.testId,
        questionId: event.questionId,
        answerId: event.answerId,
        tries: event.tries,
        isCorrect: event.isCorrect,
      );
      
      if (response.success && response.data != null) {
        emit(UserTestAnswerChecked(response.data!));
      } else {
        emit(UserTestError(response.message));
      }
    } catch (e) {
      emit(UserTestError(e.toString()));
    }
  }

  void _groupTestsBySubject() {
    _testsBySubject = {};
    for (final test in _cachedTests) {
      final subjectKey = test.subjectId ?? test.subjectName;
      if (!_testsBySubject.containsKey(subjectKey)) {
        _testsBySubject[subjectKey] = [];
      }
      _testsBySubject[subjectKey]!.add(test);
    }
  }

  void _updateCachedTest(UserTest updatedTest) {
    final index = _cachedTests.indexWhere((t) => t.id == updatedTest.id);
    if (index >= 0) {
      _cachedTests[index] = updatedTest;
      _groupTestsBySubject();
    }
  }
}
