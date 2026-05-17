import 'package:equatable/equatable.dart';

class ModuleChapter extends Equatable {
  // Status constants
  static const String statusNotStarted = 'not_started';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusLocked = 'locked';

  final String id;
  final String name;
  final String? description;
  final String? theory; // Theory content for this chapter
  final String moduleId;
  final int order;
  final String? logo;
  final int questionCount;
  final String status;
  final bool isEnabled;
  final bool isImportant;
  final bool hasHots;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? currentQuestionId; // From API: current_question_id
  final String? userStatus;
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

  const ModuleChapter({
    required this.id,
    required this.name,
    this.description,
    this.theory,
    required this.moduleId,
    this.order = 0,
    this.logo,
    this.questionCount = 0,
    required this.status,
    this.isEnabled = true,
    this.isImportant = false,
    this.hasHots = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.currentQuestionId,
    this.userStatus,
    this.userPercentage = 0.0,
    this.startedAt,
    this.lastAccessed,
  });

  factory ModuleChapter.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: Check theory in raw JSON
      print('🔍 ModuleChapter.fromJson - title: ${json['title']}, theory: ${json['theory']}');
      
      return ModuleChapter(
        id: json['id']?.toString() ?? '',
        name: json['title'] ?? '', // API sends 'title', not 'name'
        description: json['description'],
        theory: json['theory'], // Theory content for this chapter
        moduleId:
            '', // API doesn't send module_id, will need to be set separately
        order: json['order'] ?? 0,
        logo: json['logo'],
        questionCount: json['content_count'] ??
            0, // API sends 'content_count', not 'question_count'
        status:
            json['status'] ?? 'not_started', // Default status if not provided
        isEnabled:
            json['is_enabled'] ?? true, // Default to true if not provided
        isImportant: json['is_important'] ?? false,
        hasHots: json['has_hots'] ?? false,
        createdBy: json['created_by']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
        currentQuestionId: json['current_question_id']?.toString(),
        userStatus: null, // API doesn't send this
        userPercentage: 0.0, // API doesn't send this, default to 0
        startedAt: null, // API doesn't send this
        lastAccessed: null, // API doesn't send this
      );
    } catch (e) {
      print('Error parsing ModuleChapter from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theory': theory,
      'module_id': moduleId,
      'order': order,
      'logo': logo,
      'question_count': questionCount,
      'status': status,
      'is_enabled': isEnabled,
      'is_important': isImportant,
      'has_hots': hasHots,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'current_question_id': currentQuestionId,
      'user_status': userStatus,
      'user_percentage': userPercentage,
      'started_at': startedAt?.toIso8601String(),
      'last_accessed': lastAccessed?.toIso8601String(),
    };
  }

  ModuleChapter copyWith({
    String? id,
    String? name,
    String? description,
    String? theory,
    String? moduleId,
    int? order,
    String? logo,
    int? questionCount,
    String? status,
    bool? isEnabled,
    bool? isImportant,
    bool? hasHots,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentQuestionId,
    String? userStatus,
    double? userPercentage,
    DateTime? startedAt,
    DateTime? lastAccessed,
  }) {
    return ModuleChapter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      theory: theory ?? this.theory,
      moduleId: moduleId ?? this.moduleId,
      order: order ?? this.order,
      logo: logo ?? this.logo,
      questionCount: questionCount ?? this.questionCount,
      status: status ?? this.status,
      isEnabled: isEnabled ?? this.isEnabled,
      isImportant: isImportant ?? this.isImportant,
      hasHots: hasHots ?? this.hasHots,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      userStatus: userStatus ?? this.userStatus,
      userPercentage: userPercentage ?? this.userPercentage,
      startedAt: startedAt ?? this.startedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  static ModuleChapter empty() {
    return ModuleChapter(
      id: '',
      name: '',
      theory: null,
      moduleId: '',
      status: 'not_started',
      isEnabled: false,
      isImportant: false,
      hasHots: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        theory,
        moduleId,
        order,
        logo,
        questionCount,
        status,
        isEnabled,
        isImportant,
        hasHots,
        createdBy,
        createdAt,
        updatedAt,
        currentQuestionId,
        userStatus,
        userPercentage,
        startedAt,
        lastAccessed,
      ];
}
