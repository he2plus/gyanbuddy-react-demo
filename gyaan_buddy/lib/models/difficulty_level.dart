enum DifficultyLevel {
  easy('easy', 'Easy'),
  medium('medium', 'Medium'),
  hard('hard', 'Hard');

  const DifficultyLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DifficultyLevel.medium,
    );
  }
}
