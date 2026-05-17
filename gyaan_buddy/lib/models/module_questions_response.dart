import 'package:equatable/equatable.dart';
import 'module_chapter_model.dart';
import 'question_model.dart';
import 'theory_content_model.dart';
import 'module_content_item_model.dart';

// Module questions response model
class ModuleQuestionsResponse extends Equatable {
  final ModuleInfo module;
  final List<ModuleChapter> chapters;
  final List<ModuleQuestionItem> questions;
  final List<ModuleTheoryItem> theories;
  final List<ModuleContentItem> allContent;

  const ModuleQuestionsResponse({
    required this.module,
    required this.chapters,
    required this.questions,
    required this.theories,
    required this.allContent,
  });

  factory ModuleQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return ModuleQuestionsResponse(
      module: ModuleInfo.fromJson(json['module'] ?? {}),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((chapter) => ModuleChapter.fromJson(chapter))
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((question) => ModuleQuestionItem.fromJson(question))
              .toList() ??
          [],
      theories: (json['theories'] as List<dynamic>?)
              ?.map((theory) => ModuleTheoryItem.fromJson(theory))
              .toList() ??
          [],
      allContent: (json['all_content'] as List<dynamic>?)
              ?.map((content) => ModuleContentItem.fromJson(content))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module.toJson(),
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'questions': questions.map((question) => question.toJson()).toList(),
      'theories': theories.map((theory) => theory.toJson()).toList(),
      'all_content': allContent.map((content) => content.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [module, chapters, questions, theories, allContent];
}

// Module info model
class ModuleInfo extends Equatable {
  final String id;
  final String name;
  final String description;
  final String subjectName;
  final int totalChapters;
  final int totalQuestions;
  final int totalTheories;

  const ModuleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectName,
    required this.totalChapters,
    required this.totalQuestions,
    required this.totalTheories,
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      subjectName: json['subject_name'] ?? '',
      totalChapters: json['total_chapters'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      totalTheories: json['total_theories'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject_name': subjectName,
      'total_chapters': totalChapters,
      'total_questions': totalQuestions,
      'total_theories': totalTheories,
    };
  }

  @override
  List<Object?> get props => [id, name, description, subjectName, totalChapters, totalQuestions, totalTheories];
}

// Module question item model
class ModuleQuestionItem extends Equatable {
  final String id;
  final String contentType;
  final String contentTypeDisplay;
  final int order;
  final Question? question;
  final TheoryContent? theory;
  final String? moduleName;
  final String? createdBy;

  const ModuleQuestionItem({
    required this.id,
    required this.contentType,
    required this.contentTypeDisplay,
    required this.order,
    this.question,
    this.theory,
    this.moduleName,
    this.createdBy,
  });

  factory ModuleQuestionItem.fromJson(Map<String, dynamic> json) {
    return ModuleQuestionItem(
      id: json['id']?.toString() ?? '',
      contentType: json['content_type'] ?? '',
      contentTypeDisplay: json['content_type_display'] ?? '',
      order: json['order'] ?? 1,
      question: json['question'] != null ? Question.fromJson(json['question']) : null,
      theory: json['theory'] != null ? TheoryContent.fromJson(json['theory']) : null,
      moduleName: json['module_name'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'content_type_display': contentTypeDisplay,
      'order': order,
      'question': question?.toJson(),
      'theory': theory?.toJson(),
      'module_name': moduleName,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, contentType, contentTypeDisplay, order, question, theory, moduleName, createdBy];
}

// Module theory item model
class ModuleTheoryItem extends Equatable {
  final String id;
  final String contentType;
  final String contentTypeDisplay;
  final int order;
  final Question? question;
  final TheoryContent? theory;
  final String? moduleName;
  final String? createdBy;

  const ModuleTheoryItem({
    required this.id,
    required this.contentType,
    required this.contentTypeDisplay,
    required this.order,
    this.question,
    this.theory,
    this.moduleName,
    this.createdBy,
  });

  factory ModuleTheoryItem.fromJson(Map<String, dynamic> json) {
    return ModuleTheoryItem(
      id: json['id']?.toString() ?? '',
      contentType: json['content_type'] ?? '',
      contentTypeDisplay: json['content_type_display'] ?? '',
      order: json['order'] ?? 1,
      question: json['question'] != null ? Question.fromJson(json['question']) : null,
      theory: json['theory'] != null ? TheoryContent.fromJson(json['theory']) : null,
      moduleName: json['module_name'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'content_type_display': contentTypeDisplay,
      'order': order,
      'question': question?.toJson(),
      'theory': theory?.toJson(),
      'module_name': moduleName,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, contentType, contentTypeDisplay, order, question, theory, moduleName, createdBy];
}

