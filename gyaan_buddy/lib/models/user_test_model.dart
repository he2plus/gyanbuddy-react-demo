/// Model classes for Tests feature

class Test {
  final String id;
  final DateTime testDatetime;
  final int? duration;
  final String? classGroupId;
  final String? classGroupName;
  final String? subjectId;
  final String? subjectName;
  final String? subjectColor;
  final String? subjectLogo;
  final String? moduleId;
  final String? moduleName;
  final String? moduleChapterId;
  final String? chapterTitle;
  final int questionCount;
  final UserTestProgress? userProgress;

  Test({
    required this.id,
    required this.testDatetime,
    this.duration,
    this.classGroupId,
    this.classGroupName,
    this.subjectId,
    this.subjectName,
    this.subjectColor,
    this.subjectLogo,
    this.moduleId,
    this.moduleName,
    this.moduleChapterId,
    this.chapterTitle,
    required this.questionCount,
    this.userProgress,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    // Handle subject_logo which can be a string URL or null
    String? subjectLogo;
    if (json['subject_logo'] != null) {
      subjectLogo = json['subject_logo'].toString();
    }
    
    return Test(
      id: json['id']?.toString() ?? '',
      testDatetime: (DateTime.tryParse(json['test_datetime'] ?? '') ?? DateTime.now()).toLocal(),
      duration: json['duration'],
      classGroupId: json['class_group']?.toString(),
      classGroupName: json['class_group_name'],
      subjectId: json['subject']?.toString(),
      subjectName: json['subject_name'],
      subjectColor: json['subject_color'],
      subjectLogo: subjectLogo,
      moduleId: json['module']?.toString(),
      moduleName: json['module_name'],
      moduleChapterId: json['module_chapter']?.toString(),
      chapterTitle: json['chapter_title'],
      questionCount: json['question_count'] ?? 0,
      userProgress: json['user_progress'] != null
          ? UserTestProgress.fromJson(json['user_progress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_datetime': testDatetime.toIso8601String(),
      'duration': duration,
      'class_group': classGroupId,
      'class_group_name': classGroupName,
      'subject': subjectId,
      'subject_name': subjectName,
      'subject_color': subjectColor,
      'subject_logo': subjectLogo,
      'module': moduleId,
      'module_name': moduleName,
      'module_chapter': moduleChapterId,
      'chapter_title': chapterTitle,
      'question_count': questionCount,
      'user_progress': userProgress?.toJson(),
    };
  }

  /// Check if test is completed
  bool get isCompleted => userProgress?.status == 'completed';

  /// Check if test is in progress
  bool get isInProgress => userProgress?.status == 'in_progress';

  /// Check if test hasn't started
  bool get isNotStarted => userProgress == null || userProgress?.status == 'not_started';

  /// Get progress percentage
  int get progressPercentage => userProgress?.percentage ?? 0;

  /// Get status display text
  String get statusText {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In Progress';
    return 'Not Started';
  }
  
  /// Get test title (chapter title or module name)
  String get title => chapterTitle ?? moduleName ?? 'Test';
  
  /// Get description
  String get description => moduleName ?? '';
  
  /// Get the test end time (testDatetime + duration)
  DateTime get testEndTime {
    final durationMinutes = duration ?? 60; // Default to 60 minutes if no duration
    return testDatetime.add(Duration(minutes: durationMinutes));
  }
  
  /// Check if test is scheduled for the future (not yet available)
  bool get isUpcoming {
    final now = DateTime.now();
    return testDatetime.isAfter(now);
  }
  
  /// Check if test is currently in its active window (between testDatetime and testDatetime + duration)
  bool get isInActiveWindow {
    final now = DateTime.now();
    return !testDatetime.isAfter(now) && now.isBefore(testEndTime);
  }
  
  /// Check if test window has passed (overdue)
  bool get isOverdue {
    final now = DateTime.now();
    return !now.isBefore(testEndTime); // now >= testEndTime
  }
  
  /// Check if test is skipped (overdue and not completed)
  bool get isSkipped {
    return isOverdue && !isCompleted;
  }
  
  /// Check if test can be attempted (in active window and not completed)
  bool get canAttempt {
    return isInActiveWindow && !isCompleted;
  }
  
  /// Get test status for display
  TestStatus get testStatus {
    if (isCompleted) return TestStatus.completed;
    if (isUpcoming) return TestStatus.upcoming;
    if (isSkipped) return TestStatus.skipped;
    if (isInActiveWindow) return TestStatus.active;
    return TestStatus.upcoming;
  }
}

/// Enum for test status
enum TestStatus {
  upcoming,   // Test is scheduled for future
  active,     // Test is in its active window
  skipped,    // Test window passed without completion
  completed,  // Test was completed
}

// Alias for backward compatibility
typedef UserTest = Test;

class UserTestProgress {
  final String id;
  final String? accountId;
  final String? user;
  final String? testId;
  final String status;
  final int percentage;
  final int score;
  final int totalQuestions;
  final int questionsAttempted;
  final int correctAnswers;
  final int wrongAnswers;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessed;
  final int timeSpentSeconds;
  final int expEarned;
  final String? currentQuestionId;
  final String? currentQuestionText;

  UserTestProgress({
    required this.id,
    this.accountId,
    this.user,
    this.testId,
    required this.status,
    required this.percentage,
    required this.score,
    required this.totalQuestions,
    required this.questionsAttempted,
    required this.correctAnswers,
    required this.wrongAnswers,
    this.startedAt,
    this.completedAt,
    this.lastAccessed,
    required this.timeSpentSeconds,
    required this.expEarned,
    this.currentQuestionId,
    this.currentQuestionText,
  });

  factory UserTestProgress.fromJson(Map<String, dynamic> json) {
    return UserTestProgress(
      id: json['id']?.toString() ?? '',
      accountId: json['account']?.toString(),
      user: json['user'],
      testId: json['test']?.toString(),
      status: json['status'] ?? 'not_started',
      percentage: json['percentage'] ?? 0,
      score: json['score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      questionsAttempted: json['questions_attempted'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      lastAccessed: json['last_accessed'] != null
          ? DateTime.tryParse(json['last_accessed'])
          : null,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      expEarned: json['exp_earned'] ?? 0,
      currentQuestionId: json['current_question_id']?.toString(),
      currentQuestionText: json['current_question_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': accountId,
      'user': user,
      'test': testId,
      'status': status,
      'percentage': percentage,
      'score': score,
      'total_questions': totalQuestions,
      'questions_attempted': questionsAttempted,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_accessed': lastAccessed?.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
      'exp_earned': expEarned,
      'current_question_id': currentQuestionId,
      'current_question_text': currentQuestionText,
    };
  }
  
  /// Check if passed (more than 50% correct)
  bool get isPassed => totalQuestions > 0 && (correctAnswers / totalQuestions) >= 0.5;
  
  /// Get accuracy percentage
  double get accuracy => questionsAttempted > 0 ? (correctAnswers / questionsAttempted) * 100 : 0;
}

/// Model for test question data
class TestQuestion {
  final String id;
  final String questionText;
  final String? image;
  final String questionType;
  final int expPoints;
  final String difficultyLevel;
  final String? explanation;
  final String? hint;
  final bool isHots;
  final List<TestQuestionOption> options;

  TestQuestion({
    required this.id,
    required this.questionText,
    this.image,
    required this.questionType,
    required this.expPoints,
    required this.difficultyLevel,
    this.explanation,
    this.hint,
    this.isHots = false,
    required this.options,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      image: json['image'],
      questionType: json['question_type'] ?? 'mcq_single',
      expPoints: json['exp_points'] ?? 10,
      difficultyLevel: json['difficulty_level'] ?? 'medium',
      explanation: json['explanation'],
      hint: json['hint'],
      isHots: json['is_hots'] ?? false,
      options: (json['options'] as List<dynamic>?)
          ?.map((option) => TestQuestionOption.fromJson(option))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'image': image,
      'question_type': questionType,
      'exp_points': expPoints,
      'difficulty_level': difficultyLevel,
      'explanation': explanation,
      'hint': hint,
      'is_hots': isHots,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }

  /// Check if this is a multiple choice question with single correct answer
  bool get isMcqSingle => questionType.toLowerCase() == 'mcq_single';

  /// Check if this is a multiple choice question with multiple correct answers
  bool get isMcqMultiple => questionType.toLowerCase() == 'mcq_multiple';

  /// Check if this is a short answer question
  bool get isShortAnswer {
    final type = questionType.toLowerCase();
    return type == 'short_answer' || type == 'shortanswer' || type == 'short';
  }

  /// Check if this is a rearrange question
  bool get isRearrange {
    final type = questionType.toLowerCase();
    return type == 'rearrange' || type == 're_arrange' || type == 'reorder';
  }

  /// Check if this question has a hint available
  bool get hasHint => hint != null && hint!.isNotEmpty;
}

/// Model for test question option
class TestQuestionOption {
  final String id;
  final String optionText;
  final int order;
  final bool isCorrect;

  TestQuestionOption({
    required this.id,
    required this.optionText,
    required this.order,
    required this.isCorrect,
  });

  factory TestQuestionOption.fromJson(Map<String, dynamic> json) {
    return TestQuestionOption(
      id: json['id']?.toString() ?? '',
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
}

/// Model for check answer response
class CheckAnswerResponse {
  final bool isCorrect;
  final int expEarned;
  final int totalExpEarned;
  final int questionsAttempted;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int percentage;
  final int score;
  final String status;
  final bool isLast;

  CheckAnswerResponse({
    required this.isCorrect,
    required this.expEarned,
    required this.totalExpEarned,
    required this.questionsAttempted,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.score,
    required this.status,
    required this.isLast,
  });

  factory CheckAnswerResponse.fromJson(Map<String, dynamic> json) {
    return CheckAnswerResponse(
      isCorrect: json['is_correct'] ?? false,
      expEarned: json['exp_earned'] ?? 0,
      totalExpEarned: json['total_exp_earned'] ?? 0,
      questionsAttempted: json['questions_attempted'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      percentage: json['percentage'] ?? 0,
      score: json['score'] ?? 0,
      status: json['status'] ?? 'in_progress',
      isLast: json['is_last'] ?? false,
    );
  }
}
