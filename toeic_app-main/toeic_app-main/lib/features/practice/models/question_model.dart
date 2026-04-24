import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../constants/app_constants.dart';

class QuestionModel {
  final String id;
  final String partId;
  final int questionNumber;
  final String? passage;
  final String? passageTitle;
  final String? passageImageUrl;
  final String? passageTranslationData;
  final String? questionText;
  final String? questionTranslation;
  final String? optionTranslations;
  final String? keyVocabulary;
  final String? imageUrl;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;
  final String? explanation;
  final String? analysis;
  final String? evidence;
  final String? audioUrl;
  final String? transcript;
  final String? topicTag;

  QuestionModel({
    required this.id,
    required this.partId,
    required this.questionNumber,
    this.passage,
    this.passageTitle,
    this.passageImageUrl,
    this.passageTranslationData,
    this.questionText,
    this.questionTranslation,
    this.optionTranslations,
    this.keyVocabulary,
    this.imageUrl,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
    this.explanation,
    this.analysis,
    this.evidence,
    this.audioUrl,
    this.transcript,
    this.topicTag,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Helper for safe int parsing
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return QuestionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      partId: (json['partId'] ?? json['part_id'] ?? '').toString(),
      questionNumber: parseInt(json['questionNumber'] ?? json['question_number'] ?? json['number']),
      passage: json['passage'],
      passageTitle: json['passageTitle'] ?? json['passage_title'],
      passageImageUrl: AppConstants.getFullUrl((json['passageImageUrl'] ?? json['passage_image_url'])?.toString()),
      passageTranslationData: (json['passageTranslationData'] ?? json['passage_translation_data'])?.toString(),
      questionText: (json['questionText'] ?? json['question_text'])?.toString(),
      questionTranslation: (json['questionTranslation'] ?? json['question_translation'])?.toString(),
      optionTranslations: (json['optionTranslations'] ?? json['option_translations'])?.toString(),
      keyVocabulary: (json['keyVocabulary'] ?? json['key_vocabulary'])?.toString(),
      imageUrl: AppConstants.getFullUrl((json['imageUrl'] ?? json['image_url'])?.toString()),
      optionA: (json['optionA'] ?? json['option_a'])?.toString(),
      optionB: (json['optionB'] ?? json['option_b'])?.toString(),
      optionC: (json['optionC'] ?? json['option_c'])?.toString(),
      optionD: (json['optionD'] ?? json['option_d'])?.toString(),
      correctAnswer: (json['correctAnswer'] ?? json['correct_answer'])?.toString(),
      explanation: (json['explanation'] ?? json['explanationText'])?.toString(),
      analysis: json['analysis']?.toString(),
      evidence: json['evidence']?.toString(),
      audioUrl: AppConstants.getFullUrl((json['audioUrl'] ?? json['audio_url'])?.toString()),
      transcript: json['transcript']?.toString(),
      topicTag: (json['topic_tag'] ?? json['topicTag'] ?? json['topic'])?.toString(),
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
          // --- NEW: General Translation Format (for Part 3/4) ---
          if (item['type'] == 'general') {
            final String content = item['content']?.toString() ?? '';
            final List<dynamic> vocabItems = item['vocabulary'] ?? [];
            
            final List<Map<String, dynamic>> sentencesList = [
              {
                'en': '', // General format has only Vietnamese content
                'vi': content,
                'vocab': vocabItems.map((v) {
                  if (v is Map) {
                    return {
                      'text': v['text']?.toString() ?? v['word']?.toString() ?? '',
                      'meaning': v['meaning']?.toString() ?? '',
                      'ipa': v['ipa']?.toString() ?? '',
                      'pos': v['pos']?.toString() ?? v['type']?.toString() ?? '',
                    };
                  }
                  return <String, String>{};
                }).toList(),
              }
            ];

            result.add({
              'label': item['label']?.toString() ?? 'Bản dịch',
              'sentences': sentencesList,
              'type': 'general',
              'content': content,
            });
            continue;
          }

          // Standard Format: {label, sentences: [{en, vi, vocab: []}]}
          // Supports both 'items' (Project Contract) and 'sentences' (Legacy)
          final dynamic sData = item['items'] ?? item['sentences'] ?? item['translation'] ?? item['passage'] ?? [];

          if (sData is List && sData.isNotEmpty) {
            final List<Map<String, dynamic>> sentencesList = [];
            for (var s in sData) {
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
                'en': s['en']?.toString() ?? s['text']?.toString() ?? '',
                'vi': s['vi']?.toString() ?? s['meaning']?.toString() ?? '',
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

  // ✅ New: Get combined passage translation text
  String get fullPassageTranslation {
    final translations = passageTranslations;
    if (translations.isEmpty) return '';
    
    return translations.map((section) {
      final label = section['label']?.toString() ?? '';
      final sentences = (section['sentences'] as List<Map<String, dynamic>>?) ?? [];
      final content = sentences.map((s) => s['vi']?.toString() ?? '').join(' ');
      
      if (label.isNotEmpty) {
        return '<b>$label</b><br/>$content';
      }
      return content;
    }).join('<br/><br/>');
  }

  // ✅ New: Get list of passage image URLs (split by CSV)
  List<String> get passageImageUrls {
    if (passageImageUrl == null || passageImageUrl!.isEmpty) return [];
    return passageImageUrl!.split(',').map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
  }
}
