enum FlashcardStatus { newCard, learning, mastered }

class Flashcard {
  final String id;
  final String userId;
  final String word;
  final String? wordType;
  final String meaning;
  final String? ipa;
  final String? exampleEn;
  final String? exampleVi;
  final FlashcardStatus status;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int reviewCount;
  final String? partId;
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.userId,
    required this.word,
    this.wordType,
    required this.meaning,
    this.ipa,
    this.exampleEn,
    this.exampleVi,
    this.status = FlashcardStatus.newCard,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.reviewCount = 0,
    this.partId,
    required this.createdAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      word: json['word'] ?? '',
      wordType: json['wordType'],
      meaning: json['meaning'] ?? '',
      ipa: json['ipa'] ?? json['pronunciation'],
      exampleEn: json['exampleEn'],
      exampleVi: json['exampleVi'],
      status: _parseStatus(json['status']),
      lastReviewedAt: json['lastReviewedAt'] != null 
          ? DateTime.parse(json['lastReviewedAt']) 
          : null,
      nextReviewAt: json['nextReviewAt'] != null 
          ? DateTime.parse(json['nextReviewAt']) 
          : null,
      reviewCount: json['reviewCount'] ?? 0,
      partId: json['partId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  static FlashcardStatus _parseStatus(String? status) {
    switch (status) {
      case 'LEARNING':
        return FlashcardStatus.learning;
      case 'MASTERED':
        return FlashcardStatus.mastered;
      default:
        return FlashcardStatus.newCard;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'word': word,
      'wordType': wordType,
      'meaning': meaning,
      'ipa': ipa,
      'exampleEn': exampleEn,
      'exampleVi': exampleVi,
      'status': status.toString().split('.').last.toUpperCase(),
      'reviewCount': reviewCount,
      'partId': partId,
    };
  }
}
