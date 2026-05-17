import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/mission_model.dart';
import '../models/next_content_model.dart';

class MissionApiService extends ApiService {
  static const String _basePath = '/missions/';

  // Get single mission by ID
  Future<MissionApiResponse<Mission>> getMissionById(String id) async {
    try {
      final response = await get('$_basePath$id');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final mission = Mission.fromJson(responseData['data']);

        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Mission loaded successfully',
          data: mission,
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load mission',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get all missions
  Future<MissionApiResponse<List<Mission>>> getAllMissions({
    int? month,
    int? year,
  }) async {
    try {
      final now = DateTime.now();
      final selectedMonth = month ?? now.month;
      final selectedYear = year ?? now.year;

      final response = await get(
        _basePath,
        queryParameters: {
          'month': selectedMonth,
          'year': selectedYear,
        },
      );

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> missionsData = responseData['data'] ?? [];
        final missions =
            missionsData.map((json) => Mission.fromJson(json)).toList();

        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Missions loaded successfully',
          data: missions,
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load missions',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Start a mission
  Future<MissionApiResponse<void>> startMission(String missionId) async {
    try {
      final response = await post('$_basePath$missionId/start');

      final responseData = response.data;

      if (responseData['success'] == true) {
        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Mission started successfully',
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to start mission',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Complete a mission
  Future<MissionApiResponse<void>> completeMission(String missionId) async {
    try {
      final response = await post('$_basePath$missionId/complete');

      final responseData = response.data;

      if (responseData['success'] == true) {
        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Mission completed successfully',
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to complete mission',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get next content for a mission
  Future<MissionApiResponse<NextContent>> getNextContent(String missionId,
      {String? currentContentId}) async {
    try {
      String endpoint = '$_basePath$missionId/get_next_content/';

      // Add query parameter if currentContentId is provided
      if (currentContentId != null) {
        endpoint += '?id=$currentContentId';
      }

      final response = await get(endpoint);

      final responseData = response.data;

      if (responseData['success'] == true) {
        // Check if data contains is_last flag (mission completed)
        if (responseData['data'] != null &&
            responseData['data']['is_last'] == true) {
          // Mission is completed, return success=false to trigger NoNextMissionContent state
          print(
              '🔵 MissionApiService: Mission completed (is_last=true), returning success=false');
          return MissionApiResponse(
            success: false,
            message: responseData['message'] ?? 'No more questions available',
          );
        }

        print(
            '🔵 MissionApiService: Parsing NextContent from data: ${responseData['data']}');
        final nextContent = NextContent.fromJson(responseData['data']);

        return MissionApiResponse(
          success: true,
          message:
              responseData['message'] ?? 'Next content loaded successfully',
          data: nextContent,
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load next content',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get mission questions (random 6 questions)
  Future<MissionApiResponse<List<MissionQuestionData>>> getMissionQuestions(
      String missionId) async {
    try {
      final response = await get('$_basePath$missionId/questions/');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> questionsData = responseData['data'] ?? [];
        final questions = questionsData
            .map((json) => MissionQuestionData.fromJson(json))
            .toList();

        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Questions loaded successfully',
          data: questions,
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load questions',
        );
      }
    } catch (e) {
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Check mission answer
  Future<MissionApiResponse<Map<String, dynamic>>> checkMissionAnswer({
    required String missionId,
    required String questionId,
    required String answerId,
    required int tries,
    required bool isCorrect,
  }) async {
    try {
      final response = await post(
        '${_basePath}check_answer/',
        data: {
          'mission_id': missionId,
          'question_id': questionId,
          'answer_id': answerId,
          'tries': tries,
          'is_correct': isCorrect,
        },
      );

      final responseData = response.data;

      print('🔵 MissionApiService: Check answer response: $responseData');

      if (responseData['success'] == true) {
        return MissionApiResponse(
          success: true,
          message: responseData['message'] ?? 'Answer checked successfully',
          data: responseData['data'] ?? {},
        );
      } else {
        return MissionApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to check answer',
        );
      }
    } catch (e) {
      print('🔵 MissionApiService: Error checking answer: $e');
      return MissionApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  String _formatErrors(Map<String, dynamic> errors) {
    if (errors.isEmpty) return 'Operation failed';

    final List<String> errorMessages = [];
    errors.forEach((field, messages) {
      if (messages is List) {
        for (final message in messages) {
          errorMessages.add('$field: $message');
        }
      } else if (messages is String) {
        errorMessages.add('$field: $messages');
      }
    });

    return errorMessages.join(', ');
  }
}

// API response wrapper for missions
class MissionApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  MissionApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });
}

// Mission Question Data model for the questions API (separate from MissionQuestion in mission_model.dart)
class MissionQuestionData {
  final String id;
  final String questionText;
  final String? image;
  final String questionType;
  final int expPoints;
  final String difficultyLevel;
  final String? explanation;
  final String? hint;
  final bool isHots;
  final List<MissionQuestionOptionData> options;
  final String? chapterName;
  final String? chapterId;

  MissionQuestionData({
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
    this.chapterName,
    this.chapterId,
  });

  factory MissionQuestionData.fromJson(Map<String, dynamic> json) {
    return MissionQuestionData(
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
              ?.map((option) => MissionQuestionOptionData.fromJson(option))
              .toList() ??
          [],
      chapterName: json['chapter_name'],
      chapterId: json['chapter_id'],
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
      'chapter_name': chapterName,
      'chapter_id': chapterId,
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

// Mission Question Option Data model
class MissionQuestionOptionData {
  final String id;
  final String optionText;
  final int order;
  final bool isCorrect;

  MissionQuestionOptionData({
    required this.id,
    required this.optionText,
    required this.order,
    required this.isCorrect,
  });

  factory MissionQuestionOptionData.fromJson(Map<String, dynamic> json) {
    return MissionQuestionOptionData(
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
