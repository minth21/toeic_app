import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../services/practice_api_service.dart';

class TouchablePassageWidget extends StatefulWidget {
  final String htmlContent;
  final List<Map<String, dynamic>> translations;
  final TextStyle? textStyle;

  const TouchablePassageWidget({
    super.key,
    required this.htmlContent,
    required this.translations,
    this.textStyle,
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
            content: Text('Không thể dịch từ này. Vui lòng thử lại.'),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveSentence(
    String sentence,
    bool isActive,
    List<dynamic> vocab,
  ) {
    if (!isActive) {
      return Text(
        sentence,
        style:
            widget.textStyle?.copyWith(height: 1.6) ??
            const TextStyle(fontSize: 16, height: 1.6),
      );
    }

    // Split by whitespace but keep punctuation attached to words
    final words = sentence.split(' ');

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: words.map((word) {
        return GestureDetector(
          onTap: () => _showWordTranslation(word, sentence, vocab),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              word,
              style:
                  widget.textStyle?.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ) ??
                  TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        );
      }).toList(),
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
                        final String currentKey =
                            '${blockIndex}_$sentenceIndex';
                        final bool isTapped = _tappedKey == currentKey;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _tappedKey = isTapped ? null : currentKey;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isTapped
                                  ? passageColor.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isTapped
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
                                        isTapped,
                                        pair['vocab'] ?? [],
                                      )
                                    : _buildInteractiveSentence(
                                        pair['en'] ?? '',
                                        isTapped,
                                        pair['vocab'] ?? [],
                                      ),
                                if (isTapped &&
                                    (pair['vi']?.isNotEmpty ?? false)) ...[
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
                                            style: TextStyle(
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
