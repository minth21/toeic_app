import 'part_model.dart';

class ExamModel {
  final String id;
  final String title;
  final String difficulty;
  final int duration; // in minutes
  final int totalQuestions;
  final int listeningQuestions;
  final int readingQuestions;
  final int progress; // 0-100
  final List<PartModel> parts;

  ExamModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.duration,
    required this.totalQuestions,
    required this.listeningQuestions,
    required this.readingQuestions,
    this.progress = 0,
    this.parts = const [],
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    var partsList = <PartModel>[];
    if (json['parts'] != null) {
      partsList = (json['parts'] as List)
          .map((i) => PartModel.fromJson(i))
          .toList();
      // Sort parts by partNumber ensure 1-7 order
      partsList.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    }

    return ExamModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Test',
      difficulty: json['difficulty'] ?? 'MEDIUM',
      duration: json['duration'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      listeningQuestions: json['listeningQuestions'] ?? 0,
      readingQuestions: json['readingQuestions'] ?? 0,
      progress: json['progress'] ?? 0,
      parts: partsList,
    );
  }
}
