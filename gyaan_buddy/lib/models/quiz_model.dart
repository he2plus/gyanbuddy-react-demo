import 'package:equatable/equatable.dart';
import 'question_model.dart';

class Quiz extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit; // in minutes
  final int totalPoints;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.timeLimit,
    required this.totalPoints,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions:
          (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      timeLimit: json['time_limit'] ?? 30,
      totalPoints: json['total_points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'time_limit': timeLimit,
      'total_points': totalPoints,
    };
  }

  @override
  List<Object?> get props =>
      [id, title, description, questions, timeLimit, totalPoints];
}
