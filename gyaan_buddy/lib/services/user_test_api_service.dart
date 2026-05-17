import 'api_service.dart';
import '../models/user_test_model.dart';

class UserTestApiService extends ApiService {
  static const String _basePath = '/tests/';

  /// Get all tests for the user's class
  Future<UserTestApiResponse<List<Test>>> getMyTests({String? status}) async {
    try {
      Map<String, dynamic>? queryParams;
      if (status != null) {
        queryParams = {'status': status};
      }
      
      final response = await get('${_basePath}my-tests/', queryParameters: queryParams);
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final List<dynamic> testsData = responseData['data'] ?? [];
        final tests = testsData
            .map((json) => Test.fromJson(json))
            .toList();
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Tests loaded successfully',
          data: tests,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load tests',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Get a single test by ID
  Future<UserTestApiResponse<Test>> getTestById(String id) async {
    try {
      final response = await get('$_basePath$id/');
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final test = Test.fromJson(responseData['data']);
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Test loaded successfully',
          data: test,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load test',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Start a test
  Future<UserTestApiResponse<Test>> startTest(String testId) async {
    try {
      final response = await post('$_basePath$testId/start/');
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final test = Test.fromJson(responseData['data']);
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Test started successfully',
          data: test,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to start test',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Complete a test
  Future<UserTestApiResponse<Test>> completeTest(String testId) async {
    try {
      final response = await post('$_basePath$testId/complete/');
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final test = Test.fromJson(responseData['data']);
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Test completed successfully',
          data: test,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to complete test',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Get all questions for a test
  Future<UserTestApiResponse<List<TestQuestion>>> getTestQuestions(String testId) async {
    try {
      final response = await get('$_basePath$testId/questions/');
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final List<dynamic> questionsData = responseData['data'] ?? [];
        final questions = questionsData
            .map((json) => TestQuestion.fromJson(json))
            .toList();
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Questions loaded successfully',
          data: questions,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to load questions',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Check an answer for a test question
  Future<UserTestApiResponse<CheckAnswerResponse>> checkAnswer({
    required String testId,
    required String questionId,
    required String answerId,
    required int tries,
    required bool isCorrect,
  }) async {
    try {
      final response = await post(
        '$_basePath$testId/check-answer/',
        data: {
          'question_id': questionId,
          'answer_id': answerId,
          'tries': tries,
          'is_correct': isCorrect,
        },
      );
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        final checkResponse = CheckAnswerResponse.fromJson(responseData['data']);
        
        return UserTestApiResponse(
          success: true,
          message: responseData['message'] ?? 'Answer checked successfully',
          data: checkResponse,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to check answer',
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Get tests grouped by subject
  Future<UserTestApiResponse<Map<String, List<Test>>>> getTestsGroupedBySubject() async {
    try {
      final response = await getMyTests();
      
      if (response.success && response.data != null) {
        final Map<String, List<Test>> groupedTests = {};
        
        for (final test in response.data!) {
          final subjectName = test.subjectName ?? 'Other';
          if (!groupedTests.containsKey(subjectName)) {
            groupedTests[subjectName] = [];
          }
          groupedTests[subjectName]!.add(test);
        }
        
        return UserTestApiResponse(
          success: true,
          message: 'Tests grouped successfully',
          data: groupedTests,
        );
      } else {
        return UserTestApiResponse(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return UserTestApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}

/// Generic API response wrapper for test operations
class UserTestApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  UserTestApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}
