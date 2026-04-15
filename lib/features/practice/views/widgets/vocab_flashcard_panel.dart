import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../constants/app_constants.dart';
import '../../../vocabulary/viewmodels/vocabulary_viewmodel.dart';

/// Swipeable flashcard panel for per-question vocabulary.
/// Shows each vocab item as a card (word + IPA + meaning).
/// Saves individual words to the Vocabulary tab.
/// Calls [onAllSwiped] when the user passes the last card.
class VocabFlashcardPanel extends StatefulWidget {
  final List<dynamic> vocabItems;
  final VoidCallback? onAllSwiped;
  final String? partId;

  const VocabFlashcardPanel({
    super.key,
    required this.vocabItems,
    this.onAllSwiped,
    this.partId,
  });

  @override
  State<VocabFlashcardPanel> createState() => _VocabFlashcardPanelState();
}

class _VocabFlashcardPanelState extends State<VocabFlashcardPanel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Set<int> _savedIndices = {};
  bool _allSwiped = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveWord(int index) async {
    if (_savedIndices.contains(index)) return;

    final item = widget.vocabItems[index] as Map<String, dynamic>;
    final vocab = <Map<String, dynamic>>[
      {
        'word': item['word'] ?? item['text'] ?? '',
        'meaning': item['meaning'] ?? '',
        'ipa': item['ipa'] ?? '',
        'lemma': item['lemma'] ?? '',
      }
    ];

    final vm = context.read<VocabularyViewModel>();
    final success = await vm.saveNewVocab(vocab, widget.partId);

    if (mounted && success) {
      setState(() => _savedIndices.add(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã lưu "${item['word'] ?? item['text']}" vào Từ vựng',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Trigger "all swiped" when user reaches/passes the last card
    if (index == widget.vocabItems.length - 1 && !_allSwiped) {
      _allSwiped = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onAllSwiped?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.vocabItems.length;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // amber-50
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Color(0xFFB45309),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Từ vựng quan trọng',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Cards ──────────────────────────────────────────────
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: count,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = widget.vocabItems[index] as Map<String, dynamic>;
                final word = item['word'] ?? item['text'] ?? '';
                final meaning = item['meaning'] ?? '';
                final ipa = item['ipa'] ?? item['pronunciation'] ?? '';
                
                // Persistent check
                final vocabVM = context.watch<VocabularyViewModel>();
                final isSaved = vocabVM.isWordSaved(word) || _savedIndices.contains(index);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Word
                            Text(
                              word,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF78350F),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ipa.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                ipa,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFB45309),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Divider line
                            Container(
                              height: 1,
                              color: const Color(0xFFFDE68A),
                              margin: const EdgeInsets.only(right: 8),
                            ),
                            const SizedBox(height: 8),
                            // Meaning
                            Text(
                              meaning,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Save button
                      GestureDetector(
                        onTap: () => _saveWord(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSaved
                                ? AppColors.success.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSaved
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            color: isSaved
                                ? AppColors.success
                                : const Color(0xFFB45309),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Dot indicators + swipe hint ──────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Dots
                // Dots - Use Wrap to prevent overflow for many items (e.g. 37+)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(count, (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                if (count > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    _currentIndex < count - 1
                        ? '← Vuốt để xem từ tiếp theo →'
                        : '✓ Đã xem hết từ vựng câu này',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFB45309).withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
