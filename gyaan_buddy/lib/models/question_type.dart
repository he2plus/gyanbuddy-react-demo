enum QuestionType {
  mcqSingle('mcq_single', 'MCQ - Single Correct Answer'),
  mcqMultiple('mcq_multiple', 'MCQ - Multiple Correct Answers'),
  shortAnswer('short_answer', 'Short Answer Question'),
  rearrange('rearrange', 'Re-arrange');

  const QuestionType(this.value, this.displayName);

  final String value;
  final String displayName;

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.mcqSingle,
    );
  }
}
