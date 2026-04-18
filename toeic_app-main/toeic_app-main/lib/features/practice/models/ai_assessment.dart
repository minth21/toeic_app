enum AiAssessmentType { performance, coaching, explanation, roadmap }

enum TrendType { up, down, stable }

class AiAssessment {
  final String id;
  final String userId;
  final String? testAttemptId;
  final AiAssessmentType type;
  final String title;
  final String summary;
  final Map<String, dynamic> content;
  final int? score;
  final TrendType? trend;
  final DateTime createdAt;
  final TestAttemptInfo? testAttempt;
  final String? teacherNote;
  final bool isPublished;

  AiAssessment({
    required this.id,
    required this.userId,
    this.testAttemptId,
    required this.type,
    required this.title,
    required this.summary,
    required this.content,
    this.score,
    this.trend,
    required this.createdAt,
    this.testAttempt,
    this.teacherNote,
    this.isPublished = true,
  });

  factory AiAssessment.fromJson(Map<String, dynamic> json) {
    return AiAssessment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      testAttemptId: json['testAttemptId'],
      type: _parseType(json['type']),
      title: json['title'] ?? 'AI Assessment',
      summary: json['summary'] ?? '',
      content: json['content'] is Map ? json['content'] : {},
      score: json['score'],
      trend: _parseTrend(json['trend']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      testAttempt: json['testAttempt'] != null 
          ? TestAttemptInfo.fromJson(json['testAttempt']) 
          : null,
      teacherNote: json['teacherNote'],
      isPublished: json['isPublished'] ?? true,
    );
  }

  static AiAssessmentType _parseType(String? type) {
    switch (type) {
      case 'COACHING':
        return AiAssessmentType.coaching;
      case 'EXPLANATION':
        return AiAssessmentType.explanation;
      case 'ROADMAP':
        return AiAssessmentType.roadmap;
      default:
        return AiAssessmentType.performance;
    }
  }

  static TrendType? _parseTrend(String? trend) {
    if (trend == null) return null;
    switch (trend) {
      case 'UP':
        return TrendType.up;
      case 'DOWN':
        return TrendType.down;
      default:
        return TrendType.stable;
    }
  }
}

class TestAttemptInfo {
  final String id;
  final int? totalScore;
  final int? correctCount;
  final int? totalQuestions;
  final String? testTitle;
  final String? partName;
  final int? partNumber;

  TestAttemptInfo({
    required this.id,
    this.totalScore,
    this.correctCount,
    this.totalQuestions,
    this.testTitle,
    this.partName,
    this.partNumber,
  });

  factory TestAttemptInfo.fromJson(Map<String, dynamic> json) {
    return TestAttemptInfo(
      id: json['id'] ?? '',
      totalScore: json['totalScore'],
      correctCount: json['correctCount'],
      totalQuestions: json['totalQuestions'],
      testTitle: json['test']?['title'],
      partName: json['part']?['partName'],
      partNumber: json['part']?['partNumber'],
    );
  }
}
