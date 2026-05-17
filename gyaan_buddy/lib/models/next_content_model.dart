import 'package:equatable/equatable.dart';

// Model for the next content API response
class NextContent extends Equatable {
  final String questionId;
  final String questionText;
  final String questionType;
  final String difficultyLevel;
  final int expPoints;
  final int order;
  final bool isHots;
  final int level;
  final List<NextContentOption> options;
  final bool isLast;

  const NextContent({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.difficultyLevel,
    required this.expPoints,
    required this.order,
    this.isHots = false,
    this.level = 1,
    required this.options,
    required this.isLast,
  });

  factory NextContent.fromJson(Map<String, dynamic> json) {
    return NextContent(
      questionId: json['question_id'] ?? '',
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'mcq_single',
      difficultyLevel: json['difficulty_level'] ?? 'medium',
      expPoints: json['exp_points'] ?? 10,
      order: json['order'] ?? 0,
      isHots: json['is_hots'] ?? false,
      level: json['level'] ?? 1,
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => NextContentOption.fromJson(option))
              .toList() ??
          [],
      isLast: json['is_last'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'question_type': questionType,
      'difficulty_level': difficultyLevel,
      'exp_points': expPoints,
      'order': order,
      'is_hots': isHots,
      'level': level,
      'options': options.map((option) => option.toJson()).toList(),
      'is_last': isLast,
    };
  }

  // Helper methods
  bool get isMultipleChoice => questionType == 'mcq_single' || questionType == 'multiple_choice';
  bool get isSingleChoice => questionType == 'mcq_single';
  bool get isRearrange => questionType == 'rearrange';
  bool get isEasy => difficultyLevel == 'easy';
  bool get isMedium => difficultyLevel == 'medium';
  bool get isHard => difficultyLevel == 'hard';

  NextContent copyWith({
    String? questionId,
    String? questionText,
    String? questionType,
    String? difficultyLevel,
    int? expPoints,
    int? order,
    bool? isHots,
    int? level,
    List<NextContentOption>? options,
    bool? isLast,
  }) {
    return NextContent(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      expPoints: expPoints ?? this.expPoints,
      order: order ?? this.order,
      isHots: isHots ?? this.isHots,
      level: level ?? this.level,
      options: options ?? this.options,
      isLast: isLast ?? this.isLast,
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        questionText,
        questionType,
        difficultyLevel,
        expPoints,
        order,
        isHots,
        level,
        options,
        isLast,
      ];

  @override
  String toString() {
    return 'NextContent(questionId: $questionId, questionText: $questionText, questionType: $questionType, difficultyLevel: $difficultyLevel, expPoints: $expPoints, order: $order, isHots: $isHots, level: $level, optionsCount: ${options.length}, isLast: $isLast)';
  }
}

// Model for options in the next content response
class NextContentOption extends Equatable {
  final String id;
  final String optionText;
  final int order;
  final bool isCorrect;

  const NextContentOption({
    required this.id,
    required this.optionText,
    required this.order,
    required this.isCorrect,
  });

  factory NextContentOption.fromJson(Map<String, dynamic> json) {
    return NextContentOption(
      id: json['id'] ?? '',
      optionText: json['option_text'] ?? '',
      order: json['order'] ?? 0,
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_text': optionText,
      'order': order,
      'is_correct': isCorrect,
    };
  }

  NextContentOption copyWith({
    String? id,
    String? optionText,
    int? order,
    bool? isCorrect,
  }) {
    return NextContentOption(
      id: id ?? this.id,
      optionText: optionText ?? this.optionText,
      order: order ?? this.order,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [id, optionText, order, isCorrect];

  @override
  String toString() {
    return 'NextContentOption(id: $id, optionText: $optionText, order: $order, isCorrect: $isCorrect)';
  }
}
