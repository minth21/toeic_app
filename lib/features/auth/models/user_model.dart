class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // STUDENT or ADMIN
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender; // MALE, FEMALE, OTHER
  final String? avatarUrl;
  final int? toeicLevel; // 1-5
  final int? targetScore; // Target TOEIC score
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
    this.toeicLevel,
    this.targetScore,
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
      toeicLevel: json['toeicLevel'] as int?,
      targetScore: json['targetScore'] as int?,
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
      if (toeicLevel != null) 'toeicLevel': toeicLevel,
      if (targetScore != null) 'targetScore': targetScore,
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
    int? toeicLevel,
    int? targetScore,
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
      toeicLevel: toeicLevel ?? this.toeicLevel,
      targetScore: targetScore ?? this.targetScore,
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
