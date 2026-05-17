import 'package:dio/dio.dart';
import '../models/module_chapter_response.dart';
import 'api_service.dart';
import '../models/module_content_model.dart';

class ModuleContentApiService extends ApiService {

  // Get module contents by module ID
  Future<ModuleContentResponse> getModuleContents(String moduleId) async {
    try {
      final response = await get('/module_chapters/$moduleId/module_content');
      
      final responseData = response.data;
      
      if (responseData['success'] == true) {
        return ModuleContentResponse.fromJson(responseData);
      } else {
        return ModuleContentResponse(
          success: false,
          data: [],
          message: responseData['message'] ?? 'Failed to load module contents',
        );
      }
    } catch (e) {
      return ModuleContentResponse(
        success: false,
        data: [],
        message: e.toString(),
      );
    }
  }

  // Refresh module contents (force fresh API call) - COMMENTED OUT: Could be consolidated with getModuleContents
  // Future<ModuleContentResponse> refreshModuleContents(String moduleId) async {
  //   try {
  //     final response = await get(
  //       '/module_chapters/$moduleId/module_content',
  //       options: Options(
  //         headers: {
  //           'Cache-Control': 'no-cache',
  //           'Pragma': 'no-cache',
  //         },
  //       ),
  //     );
      
  //     return ModuleContentResponse.fromJson(response.data);
  //   } catch (e) {
  //     return ModuleContentResponse(
  //       success: false,
  //       message: e.toString(),
  //       data: [],
  //     );
  //   }
  // }

  // Get module chapters by module ID
  Future<ModuleChapterResponse> getModuleChapters(String moduleId) async {
    try {
      final response = await get('/modules/$moduleId/module_chapters/');
      
      return ModuleChapterResponse.fromJson(response.data, moduleId: moduleId);
    } catch (e) {
      print('Error in getModuleChapters: $e');
      return ModuleChapterResponse(
        success: false,
        message: e.toString(),
        data: [],
      );
    }
  }

  // Refresh module chapters (force fresh API call) - COMMENTED OUT: Could be consolidated with getModuleChapters
  // Future<ModuleChapterResponse> refreshModuleChapters(String moduleId) async {
  //   try {
  //     final response = await get(
  //       '/modules/$moduleId/module_chapters/',
  //       options: Options(
  //           headers: {
  //             'Cache-Control': 'no-cache',
  //             'Pragma': 'no-cache',
  //           },
  //         ),
  //     );
      
  //     return ModuleChapterResponse(
  //       success: false,
  //       message: e.toString(),
  //       data: [],
  //     );
  //   } catch (e) {
  //     return ModuleChapterResponse(
  //       success: false,
  //       message: e.toString(),
  //       data: [],
  //     );
  //   }
  // }

  // Get next content for a specific chapter
  Future<ModuleContentResponse> getNextContent(String chapterId, [String? contentId]) async {
    try {
      final queryParam = contentId != null ? '?id=$contentId' : '';
      final response = await get('/module_chapters/$chapterId/get_next_content/$queryParam');
      
      final responseData = response.data;
      print('🔵 API Service: Raw response: $responseData');
      
      if (responseData['success'] == true) {
        // Check if data is null (no more content available)
        if (responseData['data'] == null) {
          print('🔵 API Service: No more content available (data is null)');
          return ModuleContentResponse(
            success: true,
            data: [], // Empty list indicates no more content
            message: responseData['message'] ?? 'No more content available',
          );
        }
        
        // Since the API returns a single ModuleContentItem, we wrap it in a list
        // to maintain compatibility with ModuleContentResponse
        final contentItem = ModuleContentItem.fromJson(responseData['data']);
        return ModuleContentResponse(
          success: true,
          data: [contentItem],
          message: responseData['message'] ?? 'Next content retrieved successfully',
        );
      } else {
        return ModuleContentResponse(
          success: false,
          data: [],
          message: responseData['message'] ?? 'Failed to get next content',
        );
      }
    } catch (e) {
      print('🔵 API Service: Error parsing response: $e');
      return ModuleContentResponse(
        success: false,
        data: [],
        message: 'Error getting next content: $e',
      );
    }
  }

  // Get next content with refresh (force fresh API call) - COMMENTED OUT: Could be consolidated with getNextContent
  // Future<ModuleContentResponse> refreshNextContent(String chapterId, [String? contentId]) async {
  //   try {
  //     final queryParam = contentId != null ? '?id=$contentId' : '';
  //     final response = await get(
  //       '/module-chapters/$chapterId/get_next_content/$queryParam',
  //       options: Options(
  //         headers: {
  //           'Cache-Control': 'no-cache',
  //           'Pragma': 'no-cache',
  //         },
  //       ),
  //     );
      
  //     final responseData = response.data;
  //     print('🔵 API Service: Refresh raw response: $responseData');
      
  //     if (responseData['success'] == true) {
  //       // Check if data is null (no more content available)
  //         if (responseData['data'] == null) {
  //           print('🔵 API Service: Refresh - No more content available (data is null)');
  //           return ModuleContentResponse(
  //             success: true,
  //             data: [], // Empty list indicates no more content
  //             message: responseData['message'] ?? 'No more content available',
  //           );
  //         }
        
  //         final contentItem = ModuleContentItem.fromJson(responseData['data']);
  //         return ModuleContentResponse(
  //             success: true,
  //             data: [contentItem],
  //             message: responseData['message'] ?? 'Next content refreshed successfully',
  //           );
  //       } else {
  //         return ModuleContentResponse(
  //           success: false,
  //           data: [],
  //           message: responseData['message'] ?? 'Failed to refresh next content',
  //         );
  //       }
  //     } catch (e) {
  //       print('🔵 API Service: Refresh error parsing response: $e');
  //       return ModuleContentResponse(
  //         success: false,
  //         data: [],
  //         message: 'Error refreshing next content: $ $e',
  //       );
  //     }
  //   }

  // Get HOTS questions for a specific chapter
  Future<Map<String, dynamic>> getHotsQuestions(String chapterId) async {
    try {
      print('🔵 API Service: Fetching HOTS questions for chapter $chapterId');
      
      final response = await get('/module_chapters/$chapterId/hots_questions/');
      
      final responseData = response.data;
      print('🔵 API Service: HOTS questions response: $responseData');
      
      if (responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'message': responseData['message'] ?? 'HOTS questions retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': responseData['message'] ?? 'Failed to get HOTS questions',
        };
      }
    } catch (e) {
      print('🔵 API Service: Error fetching HOTS questions: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Error getting HOTS questions: $e',
      };
    }
  }

  // Check answer for a specific question
  // answer can be: String (single answer ID or text), or List<String> (multiple answer IDs)
  Future<Map<String, dynamic>> checkAnswer(
    String questionId,
    dynamic answer, // Can be String or List<String>
    int tries, {
    bool isLast = false,
    bool isShortAnswer = false,
    bool isMultipleSelect = false,
  }) async {
    try {
      print('🔵 API Service: Checking answer for question $questionId, answer: $answer, tries $tries, isLast: $isLast, isShortAnswer: $isShortAnswer, isMultipleSelect: $isMultipleSelect');
      
      Map<String, dynamic> requestData = {
        'tries': tries,
        'is_last': isLast,
      };

      if (isShortAnswer) {
        // For short answer questions, send the text answer
        requestData['answer_text'] = answer as String;
      } else if (isMultipleSelect) {
        // For multiple select, send list of answer IDs
        requestData['answer_ids'] = answer as List<String>;
      } else {
        // For single select, send single answer ID
        requestData['answer_id'] = answer as String;
      }
      
      final response = await patch(
        '/questions/$questionId/check/',
        data: requestData,
      );
      
      final responseData = response.data;
      print('🔵 API Service: Check answer response: $responseData');
      
      if (responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Answer checked successfully',
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': responseData['message'] ?? 'Failed to check answer',
        };
      }
    } catch (e) {
      print('🔵 API Service: Error checking answer: $e');
      return {
        'success': false,
        'data': null,
        'message': 'Error checking answer: $e',
      };
    }
  }
}
