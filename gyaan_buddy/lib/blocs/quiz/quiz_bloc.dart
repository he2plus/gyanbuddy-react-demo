import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/quiz_models.dart';
import '../../models/question_type.dart';
import '../../models/difficulty_level.dart';
import '../../models/question_option_model.dart';
import '../../services/app_lifecycle_service.dart';

// Events
abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuiz extends QuizEvent {
  final String quizId;

  const LoadQuiz(this.quizId);

  @override
  List<Object?> get props => [quizId];
}

class StartQuiz extends QuizEvent {
  const StartQuiz();
}

class AnswerQuestion extends QuizEvent {
  final String answer;
  final Duration timeTaken;

  const AnswerQuestion({
    required this.answer,
    required this.timeTaken,
  });

  @override
  List<Object?> get props => [answer, timeTaken];
}

class NextQuestion extends QuizEvent {
  const NextQuestion();
}

class PreviousQuestion extends QuizEvent {
  const PreviousQuestion();
}

class FinishQuiz extends QuizEvent {
  const FinishQuiz();
}

class ResetQuiz extends QuizEvent {
  const ResetQuiz();
}

class UpdateTimer extends QuizEvent {
  final Duration remainingTime;

  const UpdateTimer(this.remainingTime);

  @override
  List<Object?> get props => [remainingTime];
}

class AppPaused extends QuizEvent {
  const AppPaused();
}

class AppResumed extends QuizEvent {
  const AppResumed();
}

// States
abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizLoaded extends QuizState {
  final Quiz quiz;
  final int currentQuestionIndex;
  final List<UserAnswer> userAnswers;
  final int score;
  final Duration timeRemaining;
  final bool isQuizStarted;
  final bool isQuizFinished;
  final bool isPausedByBackground;

  const QuizLoaded({
    required this.quiz,
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.score,
    required this.timeRemaining,
    required this.isQuizStarted,
    required this.isQuizFinished,
    this.isPausedByBackground = false,
  });

  QuizLoaded copyWith({
    Quiz? quiz,
    int? currentQuestionIndex,
    List<UserAnswer>? userAnswers,
    int? score,
    Duration? timeRemaining,
    bool? isQuizStarted,
    bool? isQuizFinished,
    bool? isPausedByBackground,
  }) {
    return QuizLoaded(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isQuizStarted: isQuizStarted ?? this.isQuizStarted,
      isQuizFinished: isQuizFinished ?? this.isQuizFinished,
      isPausedByBackground: isPausedByBackground ?? this.isPausedByBackground,
    );
  }

  Question get currentQuestion => quiz.questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == quiz.questions.length - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;
  bool get hasAnsweredCurrentQuestion => 
      userAnswers.any((answer) => answer.questionId == currentQuestion.id);

  @override
  List<Object?> get props => [
        quiz,
        currentQuestionIndex,
        userAnswers,
        score,
        timeRemaining,
        isQuizStarted,
        isQuizFinished,
        isPausedByBackground,
      ];
}

class QuizFinished extends QuizState {
  final QuizResult result;

  const QuizFinished(this.result);

  @override
  List<Object?> get props => [result];
}

class QuizError extends QuizState {
  final String message;

  const QuizError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  Timer? _timer;
  DateTime? _quizStartTime;
  DateTime? _backgroundPauseTime;
  bool _isPausedByBackground = false;

  QuizBloc() : super(QuizInitial()) {
    on<LoadQuiz>(_onLoadQuiz);
    on<StartQuiz>(_onStartQuiz);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<FinishQuiz>(_onFinishQuiz);
    on<ResetQuiz>(_onResetQuiz);
    on<UpdateTimer>(_onUpdateTimer);
    on<AppPaused>(_onAppPaused);
    on<AppResumed>(_onAppResumed);
  }

  void _onLoadQuiz(LoadQuiz event, Emitter<QuizState> emit) async {
    emit(QuizLoading());
    
    try {
      // Using mock data for now
      final quiz = _getMockQuiz();
      emit(QuizLoaded(
        quiz: quiz,
        currentQuestionIndex: 0,
        userAnswers: [],
        score: 0,
        timeRemaining: Duration(minutes: quiz.timeLimit),
        isQuizStarted: false,
        isQuizFinished: false,
      ));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      _quizStartTime = DateTime.now();
      
      emit(currentState.copyWith(isQuizStarted: true));
      
      // Start timer
      _startTimer();
    }
  }

  void _onAnswerQuestion(AnswerQuestion event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      final currentQuestion = currentState.currentQuestion;
      
      // Find the correct answer from options
      final correctOption = currentQuestion.options.firstWhere((option) => option.isCorrect);
      final isCorrect = event.answer == correctOption.optionText;
      final points = isCorrect ? currentQuestion.expPoints : 0;
      
      final userAnswer = UserAnswer(
        questionId: currentQuestion.id,
        selectedAnswer: event.answer,
        isCorrect: isCorrect,
        timeTaken: event.timeTaken,
      );
      
      final updatedAnswers = List<UserAnswer>.from(currentState.userAnswers);
      updatedAnswers.add(userAnswer);
      
      emit(currentState.copyWith(
        userAnswers: updatedAnswers,
        score: currentState.score + points,
      ));
    }
  }

  void _onNextQuestion(NextQuestion event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      
      if (!currentState.isLastQuestion) {
        emit(currentState.copyWith(
          currentQuestionIndex: currentState.currentQuestionIndex + 1,
        ));
      }
    }
  }

  void _onPreviousQuestion(PreviousQuestion event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      
      if (!currentState.isFirstQuestion) {
        emit(currentState.copyWith(
          currentQuestionIndex: currentState.currentQuestionIndex - 1,
        ));
      }
    }
  }

  void _onFinishQuiz(FinishQuiz event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      _stopTimer();
      
      final timeTaken = DateTime.now().difference(_quizStartTime!);
      final correctAnswers = currentState.userAnswers
          .where((answer) => answer.isCorrect)
          .length;
      final wrongAnswers = currentState.userAnswers.length - correctAnswers;
      
      final result = QuizResult(
        quizId: currentState.quiz.id,
        score: currentState.score,
        totalQuestions: currentState.quiz.questions.length,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        timeTaken: timeTaken,
        completedAt: DateTime.now(),
      );
      
      emit(QuizFinished(result));
    }
  }

  void _onResetQuiz(ResetQuiz event, Emitter<QuizState> emit) {
    _stopTimer();
    emit(QuizInitial());
  }

  void _onUpdateTimer(UpdateTimer event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      
      if (event.remainingTime.inSeconds <= 0) {
        _stopTimer();
        add(const FinishQuiz());
      } else {
        emit(currentState.copyWith(timeRemaining: event.remainingTime));
      }
    }
  }

  void _onAppPaused(AppPaused event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.isQuizStarted && !currentState.isQuizFinished) {
        _isPausedByBackground = true;
        _backgroundPauseTime = DateTime.now();
        _pauseTimer();
        emit(currentState.copyWith(isPausedByBackground: true));
      }
    }
  }

  void _onAppResumed(AppResumed event, Emitter<QuizState> emit) {
    if (state is QuizLoaded) {
      final currentState = state as QuizLoaded;
      if (currentState.isQuizStarted && !currentState.isQuizFinished && _isPausedByBackground) {
        // Check if app was in background for more than 2 minutes
        if (_backgroundPauseTime != null) {
          final backgroundDuration = DateTime.now().difference(_backgroundPauseTime!);
          if (backgroundDuration.inMinutes > 2) {
            // If in background too long, finish the quiz
            add(const FinishQuiz());
          } else {
            // Resume the timer
            _isPausedByBackground = false;
            _backgroundPauseTime = null;
            _resumeTimer();
            emit(currentState.copyWith(isPausedByBackground: false));
          }
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is QuizLoaded) {
        final currentState = state as QuizLoaded;
        if (!currentState.isPausedByBackground) {
          final remaining = currentState.timeRemaining - const Duration(seconds: 1);
          add(UpdateTimer(remaining));
        }
      }
    });
    
    // Register with lifecycle service
    AppLifecycleService().registerTimer('quiz_timer', _timer!);
  }

  void _pauseTimer() {
    _timer?.cancel();
    AppLifecycleService().unregisterTimer('quiz_timer');
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    AppLifecycleService().unregisterTimer('quiz_timer');
  }

  Quiz _getMockQuiz() {
    return Quiz(
      id: '1',
      title: 'General Knowledge Quiz',
      description: 'Test your general knowledge with these questions',
      questions: [
        Question(
          id: '1',
          questionText: 'What is the capital of France?',
          questionType: QuestionType.mcqSingle,
          expPoints: 10,
          difficultyLevel: DifficultyLevel.easy,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          options: [
            QuestionOption(
              id: '1_1',
              questionId: '1',
              optionText: 'London',
              isCorrect: false,
              order: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '1_2',
              questionId: '1',
              optionText: 'Berlin',
              isCorrect: false,
              order: 2,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '1_3',
              questionId: '1',
              optionText: 'Paris',
              isCorrect: true,
              order: 3,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '1_4',
              questionId: '1',
              optionText: 'Madrid',
              isCorrect: false,
              order: 4,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        Question(
          id: '2',
          questionText: 'Which planet is known as the Red Planet?',
          questionType: QuestionType.mcqSingle,
          expPoints: 10,
          difficultyLevel: DifficultyLevel.easy,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          options: [
            QuestionOption(
              id: '2_1',
              questionId: '2',
              optionText: 'Venus',
              isCorrect: false,
              order: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '2_2',
              questionId: '2',
              optionText: 'Mars',
              isCorrect: true,
              order: 2,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '2_3',
              questionId: '2',
              optionText: 'Jupiter',
              isCorrect: false,
              order: 3,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '2_4',
              questionId: '2',
              optionText: 'Saturn',
              isCorrect: false,
              order: 4,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        Question(
          id: '3',
          questionText: 'What is 2 + 2?',
          questionType: QuestionType.mcqSingle,
          expPoints: 10,
          difficultyLevel: DifficultyLevel.easy,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          options: [
            QuestionOption(
              id: '3_1',
              questionId: '3',
              optionText: '3',
              isCorrect: false,
              order: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '3_2',
              questionId: '3',
              optionText: '4',
              isCorrect: true,
              order: 2,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '3_3',
              questionId: '3',
              optionText: '5',
              isCorrect: false,
              order: 3,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            QuestionOption(
              id: '3_4',
              questionId: '3',
              optionText: '6',
              isCorrect: false,
              order: 4,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ],
      timeLimit: 5,
      totalPoints: 30,
    );
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
