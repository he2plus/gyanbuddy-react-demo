import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model to hold subject-specific progress data for a user
class SubjectProgress extends Equatable {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final String? color;
  final int questionsAttempted;
  final int correctAnswers;
  final double accuracy;
  final double avgTries;
  final int firstTryCorrect;
  final double firstTryAccuracy;
  final double avgCompletion;
  final int chaptersCompleted;
  final int totalChaptersInAttemptedModules;
  final double chapterCompletionRate;

  const SubjectProgress({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    this.color,
    required this.questionsAttempted,
    required this.correctAnswers,
    required this.accuracy,
    required this.avgTries,
    required this.firstTryCorrect,
    required this.firstTryAccuracy,
    required this.avgCompletion,
    required this.chaptersCompleted,
    required this.totalChaptersInAttemptedModules,
    required this.chapterCompletionRate,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) {
    return SubjectProgress(
      subjectId: json['subject_id']?.toString() ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectCode: json['subject_code'],
      color: json['color'],
      questionsAttempted: json['questions_attempted'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      accuracy: _parseDouble(json['accuracy']),
      avgTries: _parseDouble(json['avg_tries']),
      firstTryCorrect: json['first_try_correct'] ?? 0,
      firstTryAccuracy: _parseDouble(json['first_try_accuracy']),
      avgCompletion: _parseDouble(json['avg_completion']),
      chaptersCompleted: json['chapters_completed'] ?? 0,
      totalChaptersInAttemptedModules: json['total_chapters_in_attempted_modules'] ?? 0,
      chapterCompletionRate: _parseDouble(json['chapter_completion_rate']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'color': color,
      'questions_attempted': questionsAttempted,
      'correct_answers': correctAnswers,
      'accuracy': accuracy,
      'avg_tries': avgTries,
      'first_try_correct': firstTryCorrect,
      'first_try_accuracy': firstTryAccuracy,
      'avg_completion': avgCompletion,
      'chapters_completed': chaptersCompleted,
      'total_chapters_in_attempted_modules': totalChaptersInAttemptedModules,
      'chapter_completion_rate': chapterCompletionRate,
    };
  }

  /// Get color as Flutter Color object
  Color? get colorValue {
    if (color == null || color!.isEmpty) return null;
    try {
      String hex = color!.startsWith('#') ? color!.substring(1) : color!;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Progress value for progress bar (0.0 to 1.0) based on chapter completion rate
  double get progressValue => (chapterCompletionRate / 100).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        subjectCode,
        color,
        questionsAttempted,
        correctAnswers,
        accuracy,
        avgTries,
        firstTryCorrect,
        firstTryAccuracy,
        avgCompletion,
        chaptersCompleted,
        totalChaptersInAttemptedModules,
        chapterCompletionRate,
      ];

  @override
  String toString() {
    return 'SubjectProgress(subjectId: $subjectId, subjectName: $subjectName, chapterCompletionRate: $chapterCompletionRate%)';
  }
}

