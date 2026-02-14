class QuestionModel {
  final String id;
  final String partId;
  final int questionNumber;
  final String? passage;
  final String? questionText;
  final String? imageUrl;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;
  final String? explanation;
  final String? audioUrl;
  final String? transcript;

  QuestionModel({
    required this.id,
    required this.partId,
    required this.questionNumber,
    this.passage,
    this.questionText,
    this.imageUrl,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
    this.explanation,
    this.audioUrl,
    this.transcript,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      partId: json['partId'] ?? '',
      questionNumber: json['questionNumber'] ?? 0,
      passage: json['passage'],
      questionText: json['questionText'],
      imageUrl: json['imageUrl'],
      optionA: json['optionA'],
      optionB: json['optionB'],
      optionC: json['optionC'],
      optionD: json['optionD'],
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      audioUrl: json['audioUrl'],
      transcript: json['transcript'],
    );
  }
}
