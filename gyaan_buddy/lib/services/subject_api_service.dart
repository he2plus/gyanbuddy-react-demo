import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../utils/env.dart';
import '../models/subject_model.dart';
import '../models/module_model.dart';
import '../models/module_questions_response.dart';
import '../models/question_model.dart';

class SubjectApiService extends ApiService {
  static const String _basePath = '/subjects/';

  void _log(String message) {
    if (kDebugMode && Env.enableNetworkLogging) {
      debugPrint(message);
    }
  }

  // Get all subjects
  Future<SubjectApiResponse<List<Subject>>> getAllSubjects() async {
    try {
      final response = await get(_basePath);

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> subjectsData = responseData['data'] ?? [];
        final subjects =
            subjectsData.map((json) => Subject.fromJson(json)).toList();

        return SubjectApiResponse(
          success: true,
          message: responseData['message'] ?? 'Subjects loaded successfully',
          data: subjects,
        );
      } else {
        return SubjectApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load subjects',
        );
      }
    } catch (e) {
      return SubjectApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get subject by ID
  Future<SubjectApiResponse<Subject>> getSubjectById(String id) async {
    try {
      final response = await get('$_basePath$id');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final subject = Subject.fromJson(responseData['data']);

        return SubjectApiResponse(
          success: true,
          message: responseData['message'] ?? 'Subject loaded successfully',
          data: subject,
        );
      } else {
        return SubjectApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load subject',
        );
      }
    } catch (e) {
      return SubjectApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get all modules for a subject
  Future<SubjectApiResponse<List<Module>>> getSubjectModules(
      String subjectId) async {
    _log(
        '🔵 SubjectApiService: getSubjectModules called for subjectId: $subjectId');
    _log('🔵 SubjectApiService: Full endpoint: $_basePath$subjectId/modules');

    try {
      _log(
          '🔵 SubjectApiService: Making GET request to: $_basePath$subjectId/modules');
      final response = await get('$_basePath$subjectId/modules');

      _log(
          '🔵 SubjectApiService: Response received - Status: ${response.statusCode}');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final List<dynamic> modulesData = responseData['data'] ?? [];
        _log(
            '🔵 SubjectApiService: Found ${modulesData.length} modules in response');

        final modules = modulesData.map((json) {
          _log('🔵 SubjectApiService: Parsing module');
          return Module.fromJson(json);
        }).toList();

        _log(
            '🔵 SubjectApiService: Successfully parsed ${modules.length} modules');

        return SubjectApiResponse(
          success: true,
          message: responseData['message'] ?? 'Modules loaded successfully',
          data: modules,
        );
      } else {
        _log(
            '🔵 SubjectApiService: API returned failure: ${responseData['message']}');
        return SubjectApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load modules',
        );
      }
    } catch (e) {
      _log('🔵 SubjectApiService: Exception occurred: $e');
      _log('🔵 SubjectApiService: Exception type: ${e.runtimeType}');
      return SubjectApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Get module questions for a specific chapter
  Future<SubjectApiResponse<List<Question>>> getModuleQuestions(
      String chapterId) async {
    _log(
        '🔵 SubjectApiService: getModuleQuestions called for chapterId: $chapterId');
    _log(
        '🔵 SubjectApiService: Full endpoint: /module_chapters/$chapterId/module_questions/');

    try {
      _log(
          '🔵 SubjectApiService: Making GET request to: /module_chapters/$chapterId/module_questions/');
      final response =
          await get('/module_chapters/$chapterId/module_questions/');

      _log(
          '🔵 SubjectApiService: Response received - Status: ${response.statusCode}');

      final responseData = response.data;

      if (responseData['success'] == true) {
        final questions = (responseData['data'] as List<dynamic>?)
                ?.map((questionJson) => Question.fromJson(questionJson))
                .toList() ??
            [];

        _log(
            '🔵 SubjectApiService: Successfully parsed ${questions.length} questions');

        return SubjectApiResponse(
          success: true,
          message:
              responseData['message'] ?? 'Module questions loaded successfully',
          data: questions,
        );
      } else {
        _log(
            '🔵 SubjectApiService: API returned failure: ${responseData['message']}');
        return SubjectApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load module questions',
        );
      }
    } catch (e) {
      _log('🔵 SubjectApiService: Exception occurred: $e');
      _log('🔵 SubjectApiService: Exception type: ${e.runtimeType}');
      return SubjectApiResponse(
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

// API response wrapper for subjects
class SubjectApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  SubjectApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });
}
