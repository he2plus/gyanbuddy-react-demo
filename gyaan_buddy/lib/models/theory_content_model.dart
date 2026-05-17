import 'package:equatable/equatable.dart';

// Theory content model
class TheoryContent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String descriptionPreview;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TheoryContent({
    required this.id,
    required this.title,
    required this.description,
    required this.descriptionPreview,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TheoryContent.fromJson(Map<String, dynamic> json) {
    return TheoryContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      descriptionPreview: json['description_preview'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'description_preview': descriptionPreview,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        descriptionPreview,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
