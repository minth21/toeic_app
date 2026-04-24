import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../constants/app_constants.dart';
import '../../../vocabulary/viewmodels/vocabulary_viewmodel.dart';
import '../../services/practice_api_service.dart';

class TouchablePassageWidget extends StatefulWidget {
  final String htmlContent;
  final List<Map<String, dynamic>> translations;
  final TextStyle? textStyle;
  final bool showAllTranslations;

  const TouchablePassageWidget({
    super.key,
    required this.htmlContent,
    required this.translations,
    this.textStyle,
    this.showAllTranslations = false,
  });

  @override
  State<TouchablePassageWidget> createState() => _TouchablePassageWidgetState();
}

class _TouchablePassageWidgetState extends State<TouchablePassageWidget> {
  final PracticeApiService _apiService = PracticeApiService();
  String? _tappedKey;
  bool _isTranslatingWord = false;

  void _showWordTranslation(
    String word,
    String sentence,
    List<dynamic> vocab,
  ) async {
    // 1. Check if word exists in pre-extracted vocab
    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final existingVocab = vocab.firstWhere(
      (v) =>
          v['text'].toString().toLowerCase().contains(cleanWord) ||
          cleanWord.contains(v['text'].toString().toLowerCase()),
      orElse: () => null,
    );

    if (existingVocab != null) {
      _displayTranslationSheet(
        word: existingVocab['text'],
        meaning: existingVocab['meaning'],
        ipa: existingVocab['ipa'] ?? '',
        type: '',
        example: '',
        exampleVi: '',
      );
      return;
    }

    // 2. Otherwise, call AI Translation
    setState(() => _isTranslatingWord = true);
    final data = await _apiService.translateWord(cleanWord, sentence);
    setState(() => _isTranslatingWord = false);

    if (data != null) {
      _displayTranslationSheet(
        word: data['word'] ?? word,
        meaning: data['meaning'] ?? '',
        ipa: data['ipa'] ?? '',
        type: data['type'] ?? '',
        example: data['example'] ?? '',
        exampleVi: data['exampleVi'] ?? '',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dịch thất bại. Vui lòng thử lại sau.'),
          ),
        );
      }
    }
  }

  void _displayTranslationSheet({
    required String word,
    required String meaning,
    required String ipa,
    required String type,
    required String example,
    required String exampleVi,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    if (ipa.isNotEmpty || type.isNotEmpty)
                      Text(
                        '${ipa.isNotEmpty ? ipa : ''} ${type.isNotEmpty ? '($type)' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Nghĩa Tiếng Việt',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meaning,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Ví dụ (Context)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                example,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                exampleVi,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _saveToFlashcards(word, meaning, ipa);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text(
                  'Lưu Flashcard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToFlashcards(String word, String meaning, String ipa) async {
    final vocab = <Map<String, dynamic>>[
      {
        'word': word,
        'meaning': meaning,
        'ipa': ipa,
      }
    ];

    try {
      final vm = context.read<VocabularyViewModel>();
      final success = await vm.saveNewVocab(vocab, null);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lưu thành công: $word',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildInteractiveSentence(
    String sentence,
    bool isActive,
    List<dynamic> vocab,
  ) {
    if (!isActive) {
      return RichText(
        text: TextSpan(
          text: sentence,
          style: widget.textStyle?.copyWith(height: 1.6, color: Colors.black87) ?? 
                 const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
        ),
      );
    }

    // Split by whitespace
    final words = sentence.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      spans.add(
        TextSpan(
          text: word,
          style: widget.textStyle?.copyWith(
            height: 1.6,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue.withValues(alpha: 0.3),
          ) ?? TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue.withValues(alpha: 0.3),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showWordTranslation(word, sentence, vocab),
        ),
      );
      
      // Add a space between words, but not after the last word
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
      ),
    );
  }

  bool _isChatMode(String label) {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('chat') ||
        lowerLabel.contains('message') ||
        lowerLabel.contains('conversation');
  }

  bool _isEmailMode(String label) {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('email') || lowerLabel.contains('letter');
  }

  bool _isNoticeMode(String label) {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('notice') ||
        lowerLabel.contains('announcement') ||
        lowerLabel.contains('advertisement') ||
        lowerLabel.contains('ad');
  }

  bool _isArticleMode(String label) {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('article') ||
        lowerLabel.contains('report') ||
        lowerLabel.contains('webpage');
  }

  bool _isReviewMode(String label) {
    return label.toLowerCase().contains('review');
  }

  Map<String, String>? _parseChatSentence(String sentence) {
    final chatRegex = RegExp(
      r'^((?:(?:\d{1,2}:\d{2}\s?(?:AM|PM))?\s?[\w\s]+(?:\s\(\d{1,2}:\d{2}\s?(?:AM|PM)\))?)\s?):(.*)$',
      caseSensitive: false,
    );
    final match = chatRegex.firstMatch(sentence);

    if (match != null) {
      return {
        'header': match.group(1)?.trim() ?? '',
        'content': match.group(2)?.trim() ?? '',
      };
    }
    return null;
  }

  Widget _buildChatBubble(String sentence, bool isActive, List<dynamic> vocab) {
    final parsed = _parseChatSentence(sentence);
    final header = parsed?['header'] ?? '';
    final content = parsed?['content'] ?? sentence;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(
          16,
        ).copyWith(topLeft: const Radius.circular(4)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                header,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          _buildInteractiveSentence(content, isActive, vocab),
        ],
      ),
    );
  }

  Widget _buildPassageHeader(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.translations.isEmpty) {
      return HtmlWidget(
        widget.htmlContent,
        textStyle: widget.textStyle,
        customStylesBuilder: (element) => element.localName == 'img'
            ? {
                'width': '100%',
                'height': 'auto',
                'display': 'block',
                'margin': 'auto',
              }
            : null,
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(widget.translations.length, (blockIndex) {
            final block = widget.translations[blockIndex];
            final String label = block['label'] ?? '';
            final List<dynamic> sentences = block['sentences'] ?? [];

            // UI Mode Settings
            IconData passageIcon = Icons.description;
            Color passageColor = const Color(0xFF1E3A8A);
            BoxDecoration passageDecoration = BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            );

            bool isChat = _isChatMode(label);
            if (_isEmailMode(label)) {
              passageIcon = Icons.email_outlined;
              passageColor = Colors.blue.shade700;
            } else if (_isNoticeMode(label)) {
              passageIcon = Icons.notifications_active_outlined;
              passageColor = Colors.orange.shade700;
              passageDecoration = passageDecoration.copyWith(
                color: Colors.orange.withValues(alpha: 0.02),
                border: Border.all(color: Colors.orange.shade100, width: 2),
              );
            } else if (_isArticleMode(label)) {
              passageIcon = Icons.article_outlined;
              passageColor = Colors.teal.shade700;
            } else if (_isReviewMode(label)) {
              passageIcon = Icons.rate_review_outlined;
              passageColor = Colors.purple.shade700;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              decoration: passageDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    _buildPassageHeader(label, passageIcon, passageColor),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(sentences.length, (
                        sentenceIndex,
                      ) {
                        final pair =
                            sentences[sentenceIndex] as Map<String, dynamic>;
                        final String currentKey = '${blockIndex}_$sentenceIndex';
                        final bool isTapped = _tappedKey == currentKey;
                        final bool isEffectiveTapped = isTapped || widget.showAllTranslations;

                        return GestureDetector(
                          onTap: () {
                            if (widget.showAllTranslations) return; // Disable manual toggle in "Show All" mode
                            setState(() {
                              _tappedKey = isTapped ? null : currentKey;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isEffectiveTapped
                                  ? passageColor.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isEffectiveTapped
                                    ? passageColor.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isChat
                                    ? _buildChatBubble(
                                        pair['en'] ?? '',
                                        isEffectiveTapped,
                                        pair['vocab'] ?? [],
                                      )
                                    : _buildInteractiveSentence(
                                        pair['en'] ?? '',
                                        isEffectiveTapped,
                                        pair['vocab'] ?? [],
                                      ),
                                
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: isEffectiveTapped && (pair['vi']?.isNotEmpty ?? false)
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: passageColor.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius: BorderRadius.circular(8.0),
                                              border: Border(
                                                left: BorderSide(
                                                  color: passageColor,
                                                  width: 4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.translate,
                                                  size: 16,
                                                  color: passageColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    pair['vi']!,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                      fontStyle: FontStyle.italic,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (pair['vocab'] != null &&
                                              (pair['vocab'] as List).isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8.0,
                                              runSpacing: 8.0,
                                              children: (pair['vocab'] as List).map((
                                                vocabItem,
                                              ) {
                                                final text =
                                                    vocabItem['text']?.toString() ?? '';
                                                final meaning =
                                                    vocabItem['meaning']?.toString() ??
                                                    '';
                                                if (text.isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                return ActionChip(
                                                  backgroundColor: Colors.white,
                                                  side: BorderSide(
                                                    color: passageColor.withValues(
                                                      alpha: 0.2,
                                                    ),
                                                  ),
                                                  label: RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: '$text: ',
                                                          style: TextStyle(
                                                            color: passageColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: meaning,
                                                          style: TextStyle(
                                                            color: Colors.grey.shade800,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _displayTranslationSheet(
                                                        word: text,
                                                        meaning: meaning,
                                                        ipa: vocabItem['ipa'] ?? '',
                                                        type: '',
                                                        example: '',
                                                        exampleVi: '',
                                                      ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        if (_isTranslatingWord)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
