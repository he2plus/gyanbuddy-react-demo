import 'package:equatable/equatable.dart';
import 'module_chapter_model.dart';

class ModuleChapterResponse extends Equatable {
  final bool success;
  final String message;
  final List<ModuleChapter> data;

  const ModuleChapterResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ModuleChapterResponse.fromJson(Map<String, dynamic> json,
      {String? moduleId}) {
    try {
      final responseData = json['data'] ?? [];
      print(
          'Parsing ModuleChapterResponse with ${responseData.length} chapters');
      print('Response data type: ${responseData.runtimeType}');
      if (responseData.isNotEmpty) {
        print('First item type: ${responseData.first.runtimeType}');
        print('First item: ${responseData.first}');
      }

      final List<ModuleChapter> chapters =
          responseData.map<ModuleChapter>((item) {
        if (item is! Map<String, dynamic>) {
          print('Warning: Invalid item type: ${item.runtimeType}');
          throw FormatException(
              'Expected Map<String, dynamic>, got ${item.runtimeType}');
        }

        final chapter = ModuleChapter.fromJson(item);
        // If moduleId is provided, set it on the chapter
        if (moduleId != null) {
          return chapter.copyWith(moduleId: moduleId);
        }
        return chapter;
      }).toList();

      return ModuleChapterResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        data: chapters,
      );
    } catch (e) {
      print('Error parsing ModuleChapterResponse from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((chapter) => chapter.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
