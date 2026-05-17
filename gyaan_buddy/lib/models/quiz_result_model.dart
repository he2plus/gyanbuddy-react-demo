import 'package:equatable/equatable.dart';

class QuizResult extends Equatable {
  final String quizId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final Duration timeTaken;
  final DateTime completedAt;

  const QuizResult({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeTaken,
    required this.completedAt,
  });

  double get percentage => (score / totalQuestions) * 100;

  @override
  List<Object?> get props => [
        quizId,
        score,
        totalQuestions,
        correctAnswers,
        wrongAnswers,
        timeTaken,
        completedAt,
      ];
}
