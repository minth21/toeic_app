import '../../../constants/app_constants.dart';

class UserModel {
  final String id;
  final String username;
  final String name;
  final String role; // STUDENT or ADMIN
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender; // MALE, FEMALE, OTHER
  final String? avatarUrl;
  final String? difficulty; // A1_A2, B1_B2, C1
  final int progress; // 0-100%
  final int? targetScore; // Target TOEIC score
  final bool hasPassword;
  final DateTime createdAt;
  final int totalTestsTaken;
  final int averageScore;
  final bool isFirstLogin;
  final String? classId;
  final String? className;
  final String? teacherName;
  final int estimatedScore;
  final int estimatedListening;
  final int estimatedReading;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.difficulty,
    this.progress = 0,
    this.targetScore,
    required this.hasPassword,
    required this.createdAt,
    this.totalTestsTaken = 0,
    this.averageScore = 0,
    this.isFirstLogin = true,
    this.classId,
    this.className,
    this.teacherName,
    this.estimatedScore = 0,
    this.estimatedListening = 0,
    this.estimatedReading = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      name: json['name'] as String,
      role: json['role'] as String? ?? 'STUDENT',
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      difficulty: json['difficulty'] as String?,
      progress: json['progress'] as int? ?? 0,
      targetScore: json['targetScore'] as int?,
      hasPassword: (json['hasPassword'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalTestsTaken: (json['totalAttempts'] as int? ?? json['totalTestsTaken'] as int? ?? 0),
      averageScore: json['averageScore'] as int? ?? 0,
      isFirstLogin: json['isFirstLogin'] as bool? ?? true,
      classId: json['classId'] as String?,
      className: json['className'] as String?,
      teacherName: json['teacherName'] as String?,
      estimatedScore: json['estimatedScore'] as int? ?? 0,
      estimatedListening: json['estimatedListening'] as int? ?? 0,
      estimatedReading: json['estimatedReading'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (difficulty != null) 'difficulty': difficulty,
      'progress': progress,
      if (targetScore != null) 'targetScore': targetScore,
      'hasPassword': hasPassword,
      'createdAt': createdAt.toIso8601String(),
      'totalTestsTaken': totalTestsTaken,
      'averageScore': averageScore,
      'isFirstLogin': isFirstLogin,
      if (classId != null) 'classId': classId,
      if (className != null) 'className': className,
      if (teacherName != null) 'teacherName': teacherName,
      'estimatedScore': estimatedScore,
      'estimatedListening': estimatedListening,
      'estimatedReading': estimatedReading,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? role,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? difficulty,
    int? progress,
    int? targetScore,
    bool? hasPassword,
    DateTime? createdAt,
    int? totalTestsTaken,
    int? averageScore,
    bool? isFirstLogin,
    String? classId,
    String? className,
    String? teacherName,
    int? estimatedScore,
    int? estimatedListening,
    int? estimatedReading,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      difficulty: difficulty ?? this.difficulty,
      progress: progress ?? this.progress,
      targetScore: targetScore ?? this.targetScore,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
      totalTestsTaken: totalTestsTaken ?? this.totalTestsTaken,
      averageScore: averageScore ?? this.averageScore,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherName: teacherName ?? this.teacherName,
      estimatedScore: estimatedScore ?? this.estimatedScore,
      estimatedListening: estimatedListening ?? this.estimatedListening,
      estimatedReading: estimatedReading ?? this.estimatedReading,
    );
  }

  // Helper getters
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isStudent => role.toUpperCase() == 'STUDENT';
  bool get isTeacher => role.toUpperCase() == 'TEACHER';
  bool get isSpecialist => role.toUpperCase() == 'SPECIALIST' || role.toUpperCase() == 'STAFF';
  
  // Mobile Access Control
  bool get canAccessMobileApp => isAdmin || isStudent;

  bool get isMale => gender == 'MALE';
  bool get isFemale => gender == 'FEMALE';

  // Role display label
  String get roleLabel {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppStrings.roleAdmin;
      case 'SPECIALIST':
        return AppStrings.roleSpecialist;
      case 'TEACHER':
        return AppStrings.roleTeacher;
      case 'STUDENT':
        return AppStrings.roleStudent;
      default:
        return role;
    }
  }
}
