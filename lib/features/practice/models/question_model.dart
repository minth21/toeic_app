import 'dart:convert';
import 'package:flutter/foundation.dart';

class QuestionModel {
  final String id;
  final String partId;
  final int questionNumber;
  final String? passage;
  final String? passageTranslationData;
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
    this.passageTranslationData,
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
      passageTranslationData: json['passageTranslationData'],
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

  // Helper to parse the JSON translation data
  // Handles:
  //   NEW format: { "passages": [...], "vocabulary": [...] }
  //   LEGACY format: [...] (bare array)
  // Returns a standardized list of labeled blocks.
  List<Map<String, dynamic>> get passageTranslations {
    if (passageTranslationData == null || passageTranslationData!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(passageTranslationData!);

      // Determine the actual list to parse
      List<dynamic> items;
      if (decoded is Map && decoded.containsKey('passages')) {
        // New format: { passages: [...], vocabulary: [...] }
        items = (decoded['passages'] as List?) ?? [];
      } else if (decoded is List) {
        // Legacy bare array
        items = decoded;
      } else {
        return [];
      }

      final List<Map<String, dynamic>> result = [];

      for (var item in items) {
        if (item is! Map) continue;
        // Skip internal meta objects used by admin
        if (item['type'] == '_meta') continue;

        try {
          // Standard Format: {label, sentences: [{en, vi, vocab: []}]}
          if (item.containsKey('sentences') && item['sentences'] is List) {
            final List<Map<String, dynamic>> sentencesList = [];
            for (var s in (item['sentences'] as List)) {
              if (s is! Map) continue;

              final List<Map<String, String>> vocabList = [];
              if (s.containsKey('vocab') && s['vocab'] is List) {
                for (var v in (s['vocab'] as List)) {
                  if (v is Map) {
                    vocabList.add({
                      'text': v['text']?.toString() ?? '',
                      'meaning': v['meaning']?.toString() ?? '',
                    });
                  }
                }
              }

              sentencesList.add({
                'en': s['en']?.toString() ?? '',
                'vi': s['vi']?.toString() ?? '',
                'vocab': vocabList,
              });
            }

            result.add({
              'label': item['label']?.toString() ?? '',
              'sentences': sentencesList,
            });
          }
          // Legacy/Fallback Format: Item is directly {en, vi}
          else if (item.containsKey('en') || item.containsKey('vi')) {
            result.add({
              'label': '',
              'sentences': [
                {
                  'en': item['en']?.toString() ?? '',
                  'vi': item['vi']?.toString() ?? '',
                  'vocab': <Map<String, String>>[],
                },
              ],
            });
          }
        } catch (innerError) {
          debugPrint('Error parsing passage block item: $innerError');
          // Skip one corrupted block but continue others
        }
      }
      return result;
    } catch (e) {
      debugPrint('Critical error parsing passageTranslationData: $e');
      return [];
    }
  }
}
