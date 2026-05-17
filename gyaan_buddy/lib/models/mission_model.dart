
import 'question_model.dart';
import 'question_type.dart';
import 'difficulty_level.dart';

enum MissionStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  const MissionStatus(this.value);
  final String value;

  static MissionStatus fromString(String status) {
    switch (status) {
      case 'not_started':
        return MissionStatus.notStarted;
      case 'in_progress':
        return MissionStatus.inProgress;
      case 'completed':
        return MissionStatus.completed;
      default:
        return MissionStatus.notStarted;
    }
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final DateTime missionDate;
  final List<MissionQuestion> questions;
  final int questionCount;
  final MissionStatus status;
  final bool userCompleted;
  final bool userStarted;
  // Subject information
  final String? subjectId;
  final String? subjectName;
  final String? subjectLogo;
  final String? subjectColor;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.missionDate,
    required this.questions,
    required this.questionCount,
    required this.status,
    required this.userCompleted,
    required this.userStarted,
    this.subjectId,
    this.subjectName,
    this.subjectLogo,
    this.subjectColor,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    try {
      // Handle questions as array of strings (question IDs)
      List<MissionQuestion> questions = [];
      if (json['questions'] != null) {
        final questionsList = json['questions'] as List;
        questions = questionsList
            .whereType<String>()
            .map((questionId) => MissionQuestion.fromQuestionId(
                  questionId,
                  json['id'] ?? '',
                  questionsList.indexOf(questionId),
                ))
            .toList();
      }

      // Parse subject information from nested object or direct fields
      String? subjectId;
      String? subjectName;
      String? subjectLogo;
      String? subjectColor;
      
      if (json['subject'] != null && json['subject'] is Map<String, dynamic>) {
        final subjectData = json['subject'] as Map<String, dynamic>;
        subjectId = subjectData['id'];
        subjectName = subjectData['name'];
        subjectLogo = subjectData['logo'];
        subjectColor = subjectData['color'];
      } else if (json['subject'] != null && json['subject'] is String) {
        // Subject is provided as a string ID with separate subject_name, subject_color fields
        subjectId = json['subject'] as String;
        subjectName = json['subject_name'];
        subjectLogo = json['subject_logo'];
        subjectColor = json['subject_color'];
      } else {
        // Fallback to direct fields if subject is not nested
        subjectId = json['subject_id'];
        subjectName = json['subject_name'];
        subjectLogo = json['subject_logo'];
        subjectColor = json['subject_color'];
      }

      return Mission(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        missionDate: json['mission_date'] != null 
            ? DateTime.parse(json['mission_date']) 
            : DateTime.now(),
        questions: questions,
        questionCount: questions.length,
        status: json['status'] != null 
            ? MissionStatus.fromString(json['status'])
            : MissionStatus.notStarted,
        userCompleted: json['user_completed'] ?? false,
        userStarted: json['user_started'] ?? false,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectLogo: subjectLogo,
        subjectColor: subjectColor,
      );
    } catch (e) {
      print('Error parsing Mission: $e');
      print('JSON data: $json');
      rethrow;
    }
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mission_date': missionDate.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'question_count': questionCount,
      'status': status.value,
      'user_completed': userCompleted,
      'user_started': userStarted,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_logo': subjectLogo,
      'subject_color': subjectColor,
    };
  }

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? missionDate,
    List<MissionQuestion>? questions,
    int? questionCount,
    MissionStatus? status,
    bool? userCompleted,
    bool? userStarted,
    String? subjectId,
    String? subjectName,
    String? subjectLogo,
    String? subjectColor,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      missionDate: missionDate ?? this.missionDate,
      questions: questions ?? this.questions,
      questionCount: questionCount ?? this.questionCount,
      status: status ?? this.status,
      userCompleted: userCompleted ?? this.userCompleted,
      userStarted: userStarted ?? this.userStarted,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectLogo: subjectLogo ?? this.subjectLogo,
      subjectColor: subjectColor ?? this.subjectColor,
    );
  }

  @override
  String toString() {
    return 'Mission(id: $id, title: $title, description: $description, missionDate: $missionDate, questionCount: $questionCount, status: ${status.value}, userCompleted: $userCompleted, userStarted: $userStarted, subjectId: $subjectId, subjectName: $subjectName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}



class MissionQuestion {
  final String id;
  final String mission;
  final Question question;
  final int order;

  MissionQuestion({
    required this.id,
    required this.mission,
    required this.question,
    required this.order,
  });

  factory MissionQuestion.fromJson(Map<String, dynamic> json) {
    return MissionQuestion(
      id: json['id'] ?? '',
      mission: json['mission'] ?? '',
      question: json['question'] != null
          ? Question.fromJson(json['question'])
          : Question(
              id: json['id'] ?? '',
              questionText: '',
              questionType: QuestionType.mcqSingle,
              expPoints: 10,
              difficultyLevel: DifficultyLevel.medium,
              explanation: '',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              options: [],
            ),
      order: json['order'] ?? 0,
    );
  }

  // Factory constructor for creating MissionQuestion from question ID string
  factory MissionQuestion.fromQuestionId(String questionId, String missionId, int order) {
    return MissionQuestion(
      id: questionId,
      mission: missionId,
      question: Question(
        id: questionId,
        questionText: '',
        questionType: QuestionType.mcqSingle,
        expPoints: 10,
        difficultyLevel: DifficultyLevel.medium,
        explanation: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        options: [],
      ),
      order: order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission': mission,
      'question': question.toJson(),
      'order': order,
    };
  }

  @override
  String toString() {
    return 'MissionQuestion(id: $id, mission: $mission, question: ${question.questionText}, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserMissionsResponse {
  final String status;
  final String message;
  final List<Mission> data;

  UserMissionsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserMissionsResponse.fromJson(Map<String, dynamic> json) {
    return UserMissionsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? (json['data'] as List)
              .map((mission) => Mission.fromJson(mission))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((mission) => mission.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'UserMissionsResponse(status: $status, message: $message, data: ${data.length} missions)';
  }
}
