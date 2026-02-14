class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // STUDENT or ADMIN
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender; // MALE, FEMALE, OTHER
  final String? avatarUrl;
  final String? difficulty; // EASY, MEDIUM, HARD
  final int progress; // 0-100%
  final int? targetScore; // Target TOEIC score
  final bool hasPassword;
  final DateTime createdAt;
  final int totalTestsTaken;
  final int averageScore;

  UserModel({
    required this.id,
    required this.email,
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
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
      totalTestsTaken: json['totalTestsTaken'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
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
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
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
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
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
    );
  }

  // Helper getters
  bool get isAdmin => role == 'ADMIN';
  bool get isStudent => role == 'STUDENT';
  bool get isMale => gender == 'MALE';
  bool get isFemale => gender == 'FEMALE';
}
