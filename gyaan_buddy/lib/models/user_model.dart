import 'package:equatable/equatable.dart';
import 'level_model.dart';
import 'user_type.dart';
import 'subject_progress_model.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final UserType userType;
  final int admissionNumber;
  final int? rollNumber;
  final int totalExp;
  final int rewards;
  final Level? level;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? profilePicture;
  final String? bio;
  final bool isActive;
  final bool loggedInOnce;
  final String? schoolId;
  final String? schoolName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubjectProgress> subjectProgress;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    required this.admissionNumber,
    this.rollNumber,
    required this.totalExp,
    required this.rewards,
    this.level,
    this.phoneNumber,
    this.dateOfBirth,
    this.profilePicture,
    this.bio,
    required this.isActive,
    this.loggedInOnce = false,
    this.schoolId,
    this.schoolName,
    required this.createdAt,
    required this.updatedAt,
    this.subjectProgress = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      userType: _parseUserType(json['user_type']),
      admissionNumber: json['admission_number'] ?? 0,
      rollNumber: json['roll_number'],
      totalExp: json['total_exp'] ?? 0,
      rewards: json['rewards'] ?? 0,
      level: json['level'] != null ? _safeParseLevel(json['level']) : null,
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      profilePicture: json['profile_picture'],
      bio: json['bio'],
      isActive: json['is_active'] ?? true,
      loggedInOnce: json['logged_in_once'] ?? false,
      schoolId: json['school']?.toString(),
      schoolName: json['school_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['date_joined'] != null
              ? DateTime.parse(json['date_joined'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      subjectProgress: json['subject_progress'] != null
          ? (json['subject_progress'] as List)
              .map((sp) => SubjectProgress.fromJson(sp as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // Factory method specifically for leaderboard data that might have missing fields
  factory User.fromLeaderboardJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      userType: _parseUserType(json['user_type']),
      admissionNumber: _safeParseInt(json['admission_number']),
      rollNumber: _safeParseInt(json['roll_number']),
      totalExp: _safeParseInt(json['total_exp']),
      rewards: _safeParseInt(json['rewards']),
      level: json['level'] != null 
          ? _safeParseLevel(json['level'])
          : (json['level_name'] != null 
              ? _safeParseLevel(json['level_name'])
              : null),
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? _safeParseDateTime(json['date_of_birth'])
          : null,
      profilePicture: json['profile_picture'],
      bio: json['bio'],
      isActive: json['is_active'] ?? true,
      loggedInOnce: json['logged_in_once'] ?? false,
      schoolId: json['school']?.toString(),
      schoolName: json['school_name'],
      createdAt: _safeParseDateTime(json['created_at']) ?? 
          _safeParseDateTime(json['date_joined']) ?? DateTime.now(),
      updatedAt: _safeParseDateTime(json['updated_at']) ?? DateTime.now(),
      subjectProgress: json['subject_progress'] != null
          ? (json['subject_progress'] as List)
              .map((sp) => SubjectProgress.fromJson(sp as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // Safe DateTime parsing helper
  static DateTime? _safeParseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
      return null;
    }
  }

  // Safe integer parsing helper
  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $value, error: $e');
        return 0;
      }
    }
    if (value is double) return value.toInt();
    print('Unexpected type for int parsing: $value (${value.runtimeType})');
    return 0;
  }

  static Level? _safeParseLevel(dynamic levelData) {
    if (levelData == null) return null;
    if (levelData is Map<String, dynamic>) {
      try {
        return Level.fromLeaderboardJson(levelData);
      } catch (e) {
        print('Error parsing level data: $e');
        print('Level data: $levelData');
        return null;
      }
    }
    if (levelData is int) {
      // Handle case where API returns level as just an integer
      // Create a simple Level object with calculated exp ranges
      final levelNumber = levelData;
      final minExp = (levelNumber - 1) * 100;
      final maxExp = levelNumber * 100 - 1;
      return Level(
        id: levelNumber.toString(),
        name: levelNumber,
        minExp: minExp,
        maxExp: maxExp,
      );
    }
    print(
        'Unexpected type for level parsing: $levelData (${levelData.runtimeType})');
    return null;
  }

  static UserType _parseUserType(String? userType) {
    if (userType == null) return UserType.student;

    switch (userType.toLowerCase()) {
      case 'student':
        return UserType.student;
      case 'teacher':
        return UserType.teacher;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.student;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'user_type': userType.name,
      'admission_number': admissionNumber,
      'roll_number': rollNumber,
      'total_exp': totalExp,
      'rewards': rewards,
      'level': level?.toJson(),
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profile_picture': profilePicture,
      'bio': bio,
      'is_active': isActive,
      'logged_in_once': loggedInOnce,
      'school': schoolId,
      'school_name': schoolName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subject_progress': subjectProgress.map((sp) => sp.toJson()).toList(),
    };
  }

  // Computed properties
  String get fullName => '$firstName $lastName'.trim();

  int get levelNumber => level?.name ?? ((totalExp ~/ 100) + 1);

  int get expToNextLevel {
    if (level != null) {
      final currentLevelExp = level!.maxExp;
      return (currentLevelExp - totalExp).clamp(0, double.infinity).toInt();
    } else {
      // Fallback calculation if level is not provided
      final currentLevel = levelNumber;
      final expForNextLevel = currentLevel * 100;
      return (expForNextLevel - totalExp).clamp(0, double.infinity).toInt();
    }
  }

  double get levelProgress {
    if (level != null) {
      final levelExpRange = level!.expRange;
      final expInLevel = totalExp - level!.minExp;
      return (expInLevel / levelExpRange).clamp(0.0, 1.0);
    } else {
      // Fallback calculation if level is not provided
      return (totalExp % 100) / 100;
    }
  }

  String get userTypeDisplay {
    switch (userType) {
      case UserType.student:
        return 'Student';
      case UserType.teacher:
        return 'Teacher';
      case UserType.admin:
        return 'Administrator';
    }
  }

  bool get isStudent => userType == UserType.student;
  bool get isTeacher => userType == UserType.teacher;
  bool get isAdmin => userType == UserType.admin;
  
  // School-related getters
  bool get hasSchool => schoolId != null && schoolId!.isNotEmpty;
  String get schoolDisplayName => schoolName ?? 'No School Assigned';
  
  // Login status getters
  bool get hasLoggedInBefore => loggedInOnce;
  bool get isNewUser => !loggedInOnce;
  
  // Validation getters
  bool get hasValidAdmissionNumber => admissionNumber > 0;
  bool get hasValidRollNumber => rollNumber != null && rollNumber! > 0;
  bool get isStudentWithRollNumber => isStudent && hasValidRollNumber;
  
  // Display helpers
  String get admissionNumberDisplay => hasValidAdmissionNumber ? admissionNumber.toString() : 'N/A';
  String get rollNumberDisplay => hasValidRollNumber ? rollNumber.toString() : 'N/A';

  // Methods
  User copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    UserType? userType,
    int? admissionNumber,
    int? rollNumber,
    int? totalExp,
    int? rewards,
    Level? level,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? profilePicture,
    String? bio,
    bool? isActive,
    bool? loggedInOnce,
    String? schoolId,
    String? schoolName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SubjectProgress>? subjectProgress,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      totalExp: totalExp ?? this.totalExp,
      rewards: rewards ?? this.rewards,
      level: level ?? this.level,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      loggedInOnce: loggedInOnce ?? this.loggedInOnce,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subjectProgress: subjectProgress ?? this.subjectProgress,
    );
  }

  User addExp(int points) {
    if (points > 0) {
      return copyWith(totalExp: totalExp + points);
    }
    return this;
  }

  User addRewards(int points) {
    if (points > 0) {
      return copyWith(rewards: rewards + points);
    }
    return this;
  }

  @override
  List<Object?> get props => [
        id,
        username,
        firstName,
        lastName,
        email,
        userType,
        admissionNumber,
        rollNumber,
        totalExp,
        rewards,
        level,
        phoneNumber,
        dateOfBirth,
        profilePicture,
        bio,
        isActive,
        loggedInOnce,
        schoolId,
        schoolName,
        createdAt,
        updatedAt,
        subjectProgress,
      ];

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, userType: $userTypeDisplay, admissionNumber: $admissionNumber, level: $levelNumber, totalExp: $totalExp, rewards: $rewards, school: $schoolName, loggedInOnce: $loggedInOnce)';
  }
}

// User creation/update models
class CreateUserRequest {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final UserType userType;
  final int admissionNumber;
  final int? rollNumber;
  final String schoolId;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? bio;

  const CreateUserRequest({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.userType,
    required this.admissionNumber,
    this.rollNumber,
    required this.schoolId,
    this.phoneNumber,
    this.dateOfBirth,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'user_type': userType.name,
      'admission_number': admissionNumber,
      if (rollNumber != null) 'roll_number': rollNumber,
      'school': schoolId,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
      if (bio != null) 'bio': bio,
    };
  }
}

class UpdateUserRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final UserType? userType;
  final int? admissionNumber;
  final int? rollNumber;
  final String? schoolId;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? bio;

  const UpdateUserRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.userType,
    this.admissionNumber,
    this.rollNumber,
    this.schoolId,
    this.phoneNumber,
    this.dateOfBirth,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (userType != null) data['user_type'] = userType!.name;
    if (admissionNumber != null) data['admission_number'] = admissionNumber;
    if (rollNumber != null) data['roll_number'] = rollNumber;
    if (schoolId != null) data['school'] = schoolId;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toIso8601String();
    }
    if (bio != null) data['bio'] = bio;

    return data;
  }
}
