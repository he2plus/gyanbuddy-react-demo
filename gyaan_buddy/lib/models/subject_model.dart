import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String logo;
  final String? color;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int teacherCount;
  final int classCount;
  final int moduleCount;
  final bool hasDueModule;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.logo,
    this.color,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.teacherCount = 0,
    this.classCount = 0,
    this.moduleCount = 0,
    this.hasDueModule = false,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      logo: json['logo'] ?? '',
      color: json['color'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      teacherCount: json['teacher_count'] ?? 0,
      classCount: json['class_count'] ?? 0,
      moduleCount: json['module_count'] ?? 0,
      hasDueModule: json['has_due_module'] ?? false,
    );
  }

  factory Subject.empty() {
    return Subject(
      id: '',
      name: '',
      code: '',
      logo: '',
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'logo': logo,
      'color': color,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'teacher_count': teacherCount,
      'class_count': classCount,
      'module_count': moduleCount,
      'has_due_module': hasDueModule,
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? logo,
    String? color,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? teacherCount,
    int? classCount,
    int? moduleCount,
    bool? hasDueModule,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teacherCount: teacherCount ?? this.teacherCount,
      classCount: classCount ?? this.classCount,
      moduleCount: moduleCount ?? this.moduleCount,
      hasDueModule: hasDueModule ?? this.hasDueModule,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        description,
        logo,
        color,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
        teacherCount,
        classCount,
        moduleCount,
        hasDueModule,
      ];
}
