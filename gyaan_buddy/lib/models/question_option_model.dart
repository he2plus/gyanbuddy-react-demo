import 'package:equatable/equatable.dart';

// Question option model
class QuestionOption extends Equatable {
  final String id;
  final String questionId;
  final String optionText;
  final bool isCorrect;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id']?.toString() ?? '',
      questionId: json['question']?.toString() ?? '',
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      order: json['order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': questionId,
      'option_text': optionText,
      'is_correct': isCorrect,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        optionText,
        isCorrect,
        order,
        createdAt,
        updatedAt,
      ];
}
