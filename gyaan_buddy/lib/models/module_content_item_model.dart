import 'package:equatable/equatable.dart';
import 'question_model.dart';
import 'theory_content_model.dart';

// Module content item model
class ModuleContentItem extends Equatable {
  final String id;
  final String chapterId;
  final String contentType;
  final int order;
  final Question? question;
  final TheoryContent? theory;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const ModuleContentItem({
    required this.id,
    required this.chapterId,
    required this.contentType,
    required this.order,
    this.question,
    this.theory,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory ModuleContentItem.fromJson(Map<String, dynamic> json) {
    return ModuleContentItem(
      id: json['id'] ?? '',
      chapterId: json['chapter_id'] ?? json['chapter'] ?? '',
      contentType: json['type'] ?? json['content_type'] ?? '',
      order: json['order'] ?? 1,
      question: json['question'] != null
          ? Question.fromJson(json['question'])
          : null,
      theory: json['theory'] != null
          ? TheoryContent.fromJson(json['theory'])
          : null,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter': chapterId,
      'content_type': contentType,
      'order': order,
      'question': question?.toJson(),
      'theory': theory?.toJson(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Get content title based on content type
  String get contentTitle {
    if (contentType == 'question' && question != null) {
      final questionText = question!.questionText;
      return questionText.length > 100
          ? '${questionText.substring(0, 100)}...'
          : questionText;
    } else if (contentType == 'theory' && theory != null) {
      return theory!.title;
    }
    return 'Unknown Content';
  }

  // Get content preview based on content type
  String get contentPreview {
    if (contentType == 'question' && question != null) {
      final questionText = question!.questionText;
      return questionText.length > 100
          ? '${questionText.substring(0, 100)}...'
          : questionText;
    } else if (contentType == 'theory' && theory != null) {
      return theory!.descriptionPreview;
    }
    return 'No content available';
  }

  // Get content type display name
  String get contentTypeDisplay {
    switch (contentType.toLowerCase()) {
      case 'question':
        return 'Question';
      case 'theory':
        return 'Theory';
      default:
        return 'Unknown';
    }
  }

  ModuleContentItem copyWith({
    String? id,
    String? chapterId,
    String? contentType,
    int? order,
    Question? question,
    TheoryContent? theory,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return ModuleContentItem(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      contentType: contentType ?? this.contentType,
      order: order ?? this.order,
      question: question ?? this.question,
      theory: theory ?? this.theory,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chapterId,
        contentType,
        order,
        question,
        theory,
        createdBy,
        createdAt,
        updatedAt,
        isDeleted,
        deletedAt,
      ];

  @override
  String toString() {
    return 'ModuleContentItem(id: $id, contentType: $contentType, chapterId: $chapterId, order: $order)';
  }
}
