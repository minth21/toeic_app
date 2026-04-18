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
  final String status;
  final List<PartModel> parts;

  ExamModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.duration,
    required this.totalQuestions,
    required this.listeningQuestions,
    required this.readingQuestions,
    this.status = 'ACTIVE',
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
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Unknown Test').toString(),
      difficulty: (json['difficulty'] ?? 'B1_B2').toString(),
      duration: int.tryParse((json['duration'] ?? '0').toString()) ?? 0,
      totalQuestions: int.tryParse((json['totalQuestions'] ?? '0').toString()) ?? 0,
      listeningQuestions: int.tryParse((json['listeningQuestions'] ?? '0').toString()) ?? 0,
      readingQuestions: int.tryParse((json['readingQuestions'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? 'ACTIVE').toString(),
      progress: int.tryParse((json['progress'] ?? '0').toString()) ?? 0,
      parts: partsList,
    );
  }
}
