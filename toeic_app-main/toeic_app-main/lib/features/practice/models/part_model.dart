class PartModel {
  final String id;
  final int partNumber;
  final String partName;
  final int totalQuestions;
  final int completedQuestions;
  final String? instructions;
  final String? instructionImgUrl;
  final String? audioUrl;
  final int? timeLimit; // in seconds
  final int? userProgress; // AI Score or Percentage
  final String status;

  PartModel({
    required this.id,
    required this.partNumber,
    required this.partName,
    required this.totalQuestions,
    this.completedQuestions = 0,
    this.instructions,
    this.instructionImgUrl,
    this.audioUrl,
    this.timeLimit,
    this.userProgress,
    this.status = 'ACTIVE',
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    final partNumber = int.tryParse((json['partNumber'] ?? '0').toString()) ?? 0;
    return PartModel(
      id: (json['id'] ?? '').toString(),
      partNumber: partNumber,
      partName: (json['partName'] ?? _getDefaultPartName(partNumber)).toString(),
      totalQuestions: int.tryParse((json['totalQuestions'] ?? '0').toString()) ?? 0,
      completedQuestions: int.tryParse((json['_count']?['questions'] ?? '0').toString()) ?? 0,
      instructionImgUrl: json['instructionImgUrl']?.toString(),
      instructions: json['instructions']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      timeLimit: json['timeLimit'] != null ? int.tryParse(json['timeLimit'].toString()) : null,
      userProgress: json['userProgress'] != null ? int.tryParse(json['userProgress'].toString()) : null,
      status: (json['status'] ?? 'ACTIVE').toString(),
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
