import 'package:equatable/equatable.dart';
import 'question_type.dart';
import 'difficulty_level.dart';
import 'question_option_model.dart';

class Question extends Equatable {
  final String id;
  final String questionText;
  final String? image;
  final QuestionType questionType;
  final int expPoints;
  final DifficultyLevel difficultyLevel;
  final String? explanation;
  final String? hint;
  final bool isActive;
  final bool isHots;
  final int level;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuestionOption> options;

  const Question({
    required this.id,
    required this.questionText,
    this.image,
    required this.questionType,
    required this.expPoints,
    required this.difficultyLevel,
    this.explanation,
    this.hint,
    required this.isActive,
    this.isHots = false,
    this.level = 1,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      image: json['image'],
      questionType: QuestionType.fromString(json['question_type'] ?? 'mcq_single'),
      expPoints: json['exp_points'] ?? 10,
      difficultyLevel: DifficultyLevel.fromString(json['difficulty_level'] ?? 'medium'),
      explanation: json['explanation'],
      hint: json['hint'],
      isActive: json['is_active'] ?? true,
      isHots: json['is_hots'] ?? false,
      level: json['level'] ?? 1,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((option) => QuestionOption.fromJson(option))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'image': image,
      'question_type': questionType.value,
      'exp_points': expPoints,
      'difficulty_level': difficultyLevel.value,
      'explanation': explanation,
      'hint': hint,
      'is_active': isActive,
      'is_hots': isHots,
      'level': level,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'options': options.map((option) => option.toJson()).toList(),
    };
  }

  /// Return the number of correct answers for this question
  int get correctAnswersCount {
    return options.where((option) => option.isCorrect).length;
  }

  /// Return the number of options for this question
  int get optionsCount {
    return options.length;
  }

  /// Check if this is a multiple choice question with single correct answer
  bool get isMcqSingle => questionType == QuestionType.mcqSingle;

  /// Check if this is a multiple choice question with multiple correct answers
  bool get isMcqMultiple => questionType == QuestionType.mcqMultiple;

  /// Check if this is a short answer question
  bool get isShortAnswer => questionType == QuestionType.shortAnswer;

  /// Check if this is a rearrange question
  bool get isRearrange => questionType == QuestionType.rearrange;

  /// Check if this question has a hint available
  bool get hasHint => hint != null && hint!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        questionText,
        image,
        questionType,
        expPoints,
        difficultyLevel,
        explanation,
        hint,
        isActive,
        isHots,
        level,
        createdBy,
        createdAt,
        updatedAt,
        options,
      ];
}
