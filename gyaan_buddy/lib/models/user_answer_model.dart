import 'package:equatable/equatable.dart';

class UserAnswer extends Equatable {
  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final Duration timeTaken;

  const UserAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeTaken,
  });

  @override
  List<Object?> get props => [questionId, selectedAnswer, isCorrect, timeTaken];
}
