import 'package:equatable/equatable.dart';
import 'module_status.dart';

class Module extends Equatable {
  // Status constants
  static const String statusNotStarted = 'not_started';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusLocked = 'locked';

  final String id;
  final String name;
  final String? description;
  final String subjectId;
  final String? subjectName;
  final int order;
  final bool isEnabled;
  final String? logo;
  final int questionCount;
  final int chapterCount;
  final String status;
  final DateTime? dueDate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ModuleStatus userStatus;
  final double userPercentage;
  final DateTime? startedAt;
  final DateTime? lastAccessed;

  // Helper getters for status
  bool get isNotStarted => status == statusNotStarted;
  bool get isInProgress => status == statusInProgress;
  bool get isCompleted => status == statusCompleted;
  bool get isLocked => status == statusLocked;

  // Helper getter for enabled state (combines API isEnabled and status)
  bool get canAccess => isEnabled && !isLocked;

  const Module({
    required this.id,
    required this.name,
    this.description,
    required this.subjectId,
    this.subjectName,
    this.order = 0,
    required this.isEnabled,
    this.logo,
    this.questionCount = 0,
    this.chapterCount = 0,
    required this.status,
    this.dueDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.userStatus = ModuleStatus.notStarted,
    this.userPercentage = 0.0,
    this.startedAt,
    this.lastAccessed,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '', // API sends 'name'
      description: json['description'],
      subjectId: json['subject'] ?? '',
      subjectName: json['subject_name'],
      order: json['order'] ?? 0,
      isEnabled: json['is_enabled'] ?? json['is_active'] ?? true,
      logo: json['logo'],
      questionCount: json['question_count'] ?? 0, // API sends 'question_count'
      chapterCount: json['chapter_count'] ?? 0, // API sends 'chapter_count'
      status: json['status'] ?? 'not_started', // Default status if not provided
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userStatus: ModuleStatus.fromString(json['user_status'] ?? 'not_started'),
      userPercentage: (json['user_percentage'] ?? 0).toDouble(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      lastAccessed: json['last_accessed'] != null
          ? DateTime.parse(json['last_accessed'])
          : null,
    );
  }

  factory Module.empty() {
    return Module(
      id: '',
      name: '',
      subjectId: '',
      isEnabled: false,
      status: 'not_started',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subjectId,
      'subject_name': subjectName,
      'order': order,
      'is_enabled': isEnabled,
      'logo': logo,
      'question_count': questionCount,
      'chapter_count': chapterCount,
      'status': status,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_status': userStatus.value,
      'user_percentage': userPercentage,
      'started_at': startedAt?.toIso8601String(),
      'last_accessed': lastAccessed?.toIso8601String(),
    };
  }

  Module copyWith({
    String? id,
    String? name,
    String? description,
    String? subjectId,
    String? subjectName,
    int? order,
    bool? isEnabled,
    String? logo,
    int? questionCount,
    int? chapterCount,
    String? status,
    DateTime? dueDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ModuleStatus? userStatus,
    double? userPercentage,
    DateTime? startedAt,
    DateTime? lastAccessed,
  }) {
    return Module(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
      logo: logo ?? this.logo,
      questionCount: questionCount ?? this.questionCount,
      chapterCount: chapterCount ?? this.chapterCount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userStatus: userStatus ?? this.userStatus,
      userPercentage: userPercentage ?? this.userPercentage,
      startedAt: startedAt ?? this.startedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  /// Check if this module has a due date set
  bool get hasDueDate => dueDate != null;

  /// Check if this module is overdue (due date has passed)
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Get the number of days until due date (negative if overdue)
  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subjectId,
        subjectName,
        order,
        isEnabled,
        logo,
        questionCount,
        chapterCount,
        status,
        dueDate,
        createdBy,
        createdAt,
        updatedAt,
        userStatus,
        userPercentage,
        startedAt,
        lastAccessed,
      ];
}
