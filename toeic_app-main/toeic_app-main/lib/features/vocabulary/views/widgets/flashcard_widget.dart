import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/flashcard_model.dart';
import '../../../../theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback? onDelete;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    this.onDelete,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  // ── Palette Logic ──────────────────────────────────────────────
  Map<String, dynamic> _getPalette() {
    final word = widget.flashcard.word.toLowerCase();
    final h = word.trim().hashCode; // Trimming to avoid whitespace issues
    
    // Curated premium palettes
    final palettes = [
      {
        'gradient': const [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo-Violet
        'shadow': const Color(0xFF8B5CF6).withValues(alpha: 0.4),
      },
      {
        'gradient': const [Color(0xFF10B981), Color(0xFF059669)], // Emerald
        'shadow': const Color(0xFF10B981).withValues(alpha: 0.4),
      },
      {
        'gradient': const [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
        'shadow': const Color(0xFFF59E0B).withValues(alpha: 0.4),
      },
      {
        'gradient': const [Color(0xFFEC4899), Color(0xFFBE185D)], // Pink-Rose
        'shadow': const Color(0xFFEC4899).withValues(alpha: 0.4),
      },
      {
        'gradient': const [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
        'shadow': const Color(0xFF3B82F6).withValues(alpha: 0.4),
      },
      {
        'gradient': const [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple-Fuchsia
        'shadow': const Color(0xFFD946EF).withValues(alpha: 0.4),
      },
    ];

    return palettes[h.abs() % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final palette = _getPalette();
    
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildFront(palette)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(palette),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(Map<String, dynamic> palette) {
    final rawType = (widget.flashcard.wordType ?? '').toLowerCase();
    String typeStr = '';
    if (rawType.isNotEmpty) {
      if (rawType.contains('noun')) {
        typeStr = 'n';
      } else if (rawType.contains('verb')) {
        typeStr = 'v';
      } else if (rawType.contains('adjective')) {
        typeStr = 'adj';
      } else if (rawType.contains('adverb')) {
        typeStr = 'adv';
      } else if (rawType.contains('preposition')) {
        typeStr = 'prep';
      } else if (rawType.contains('conjunction')) {
        typeStr = 'conj';
      } else if (rawType.contains('pronoun')) {
        typeStr = 'pron';
      } else {
        typeStr = rawType;
      }
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette['gradient'] as List<Color>,
        ),
        boxShadow: [
          BoxShadow(
            color: palette['shadow'] as Color,
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative background element
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Word
                Text(
                  widget.flashcard.word,
                  style: AppTypography.ui(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Type & IPA Row (Centered)
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (typeStr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeStr,
                          style: AppTypography.ui(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (widget.flashcard.ipa != null && widget.flashcard.ipa!.isNotEmpty)
                      Text(
                        widget.flashcard.ipa!,
                        style: AppTypography.ui(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 32),
                // Hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('tap_to_flip').toUpperCase(),
                      style: AppTypography.ui(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
}

  Widget _buildBack(Map<String, dynamic> palette) {
    final colors = palette['gradient'] as List<Color>;
    final primaryColor = colors[0];

    final rawType = (widget.flashcard.wordType ?? '').toLowerCase();
    String typeStr = '';
    if (rawType.isNotEmpty) {
      if (rawType.contains('noun')) {
        typeStr = 'n';
      } else if (rawType.contains('verb')) {
        typeStr = 'v';
      } else if (rawType.contains('adjective')) {
        typeStr = 'adj';
      } else if (rawType.contains('adverb')) {
        typeStr = 'adv';
      } else if (rawType.contains('preposition')) {
        typeStr = 'prep';
      } else if (rawType.contains('conjunction')) {
        typeStr = 'conj';
      } else if (rawType.contains('pronoun')) {
        typeStr = 'pron';
      } else {
        typeStr = rawType;
      }
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    context.tr('meaning_caps'),
                    style: AppTypography.ui(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onDelete != null)
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Meaning and Word Type
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.flashcard.meaning,
                          style: AppTypography.friendly(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (typeStr.isNotEmpty)
                          TextSpan(
                            text: ' ($typeStr)',
                            style: AppTypography.friendly(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // IPA with Background
                  if (widget.flashcard.ipa != null && widget.flashcard.ipa!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.flashcard.ipa!,
                        style: AppTypography.friendly(
                          fontSize: 15,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],

                  // Example Section
                  if (widget.flashcard.exampleEn != null && widget.flashcard.exampleEn!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.tr('example_caps'),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.flashcard.exampleEn!,
                            style: AppTypography.friendly(
                              fontSize: 14,
                              color: const Color(0xFF334155),
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

