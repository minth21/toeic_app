class PartModel {
  final String id;
  final int partNumber;
  final String partName;
  final int totalQuestions;
  final int completedQuestions;
  final String? instructions;
  final String? instructionImgUrl;
  final int? timeLimit; // in seconds

  PartModel({
    required this.id,
    required this.partNumber,
    required this.partName,
    required this.totalQuestions,
    this.completedQuestions = 0,
    this.instructions,
    this.instructionImgUrl,
    this.timeLimit,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'] ?? '',
      partNumber: json['partNumber'] ?? 0,
      partName: json['partName'] ?? _getDefaultPartName(json['partNumber']),
      totalQuestions: json['totalQuestions'] ?? 0,
      completedQuestions: json['_count']?['questions'] ?? 0,
      instructions: json['instructions'],
      instructionImgUrl: json['instructionImgUrl'],
      timeLimit: json['timeLimit'],
    );
  }

  static String _getDefaultPartName(int? number) {
    switch (number) {
      case 1:
        return 'Photographs';
      case 2:
        return 'Question-Response';
      case 3:
        return 'Conversations';
      case 4:
        return 'Talks';
      case 5:
        return 'Incomplete Sentences';
      case 6:
        return 'Text Completion';
      case 7:
        return 'Reading Comprehension';
      default:
        return 'Unknown Part';
    }
  }
}
