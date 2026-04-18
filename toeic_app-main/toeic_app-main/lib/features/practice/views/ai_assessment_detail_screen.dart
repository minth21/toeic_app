import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../../constants/app_constants.dart';
import '../models/ai_assessment.dart';
import '../viewmodels/ai_timeline_viewmodel.dart';
import 'package:provider/provider.dart';
import 'pdf_viewer_screen.dart';
import 'dart:typed_data';

class AiAssessmentDetailScreen extends StatelessWidget {
  final AiAssessment assessment;

  const AiAssessmentDetailScreen({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final roadmapData = assessment.content['roadmap'] as List?;
    final strengths = assessment.content['strengths'] as List?;
    final weaknesses = assessment.content['weaknesses'] as List?;
    final estimatedTime = assessment.content['estimatedTimeToTarget']?.toString();
    final targetScore = assessment.content['targetScore']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 1. Premium Header with SliverAppBar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (assessment.isPublished)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                  ),
                  onPressed: () => _handlePdfExport(context),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                  ),
                  // Subtle Pattern Overlays
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(Icons.auto_awesome, size: 200, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            assessment.type == AiAssessmentType.coaching ? 'STRATEGIC ROADMAP' : 'AI PERFORMANCE',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                assessment.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (assessment.isPublished)
                              Container(
                                margin: const EdgeInsets.only(left: 12, top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Sections
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary
                    _buildGlassOverview(context),
                    const SizedBox(height: 32),

                    // Teacher Message (The most important part)
                    if (assessment.teacherNote != null && assessment.teacherNote!.isNotEmpty) ...[
                      _buildPremiumTeacherNote(context),
                      const SizedBox(height: 32),
                    ],

                    // Performance Analysis
                    if (strengths != null || weaknesses != null) ...[
                      _buildSectionHeader('PHÂN TÍCH NĂNG LỰC', Icons.analytics_rounded),
                      const SizedBox(height: 16),
                      _buildModernAnalysisCards(strengths, weaknesses),
                      const SizedBox(height: 32),
                    ],

                    // Roadmap
                    if (roadmapData != null && roadmapData.isNotEmpty) ...[
                      _buildSectionHeader('LỘ TRÌNH PHÁT TRIỂN', Icons.alt_route_rounded),
                      const SizedBox(height: 24),
                      _buildModernTimeline(context, roadmapData),
                      const SizedBox(height: 32),
                    ],

                    // Completion Target
                    if (targetScore != null || estimatedTime != null)
                      _buildModernTargetCard(context, targetScore ?? '---', estimatedTime ?? '---'),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassOverview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TỔNG QUAN',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM, yyyy').format(assessment.createdAt),
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HtmlWidget(
            assessment.summary,
            textStyle: GoogleFonts.outfit(
              height: 1.6,
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTeacherNote(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.05),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.format_quote_rounded, size: 80, color: const Color(0xFF6366F1).withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LỜI KHUYÊN TỪ GIÁO VIÊN',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6366F1),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Xác thực bởi Antigravity Center',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HtmlWidget(
                  assessment.teacherNote!,
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.6,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAnalysisCards(List? strengths, List? weaknesses) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strengths
        Expanded(
          child: _buildPointCard('MẠNH', strengths?.cast<String>() ?? [], const Color(0xFF10B981)),
        ),
        const SizedBox(width: 12),
        // Weaknesses
        Expanded(
          child: _buildPointCard('YẾU', weaknesses?.cast<String>() ?? [], const Color(0xFFF59E0B)),
        ),
      ],
    );
  }

  Widget _buildPointCard(String label, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('N/A', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textHint))
          else
            ...items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildModernTimeline(BuildContext context, List roadmap) {
    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        connectorTheme: const ConnectorThemeData(thickness: 2.0, color: Color(0xFFE2E8F0)),
        indicatorTheme: const IndicatorThemeData(size: 20.0),
      ),
      builder: TimelineTileBuilder.connected(
        indicatorBuilder: (context, index) => OutlinedDotIndicator(
          color: AppColors.primary,
          borderWidth: 2.5,
          backgroundColor: Colors.white,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
        connectorBuilder: (context, index, type) => const SolidLineConnector(color: Color(0xFFE2E8F0)),
        contentsBuilder: (context, index) {
          final phase = roadmap[index];
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          phase['phase']?.toString() ?? 'Phase ${index + 1}',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.indigo50, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          phase['duration']?.toString() ?? '',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (phase['focus'] is List)
                    ...(phase['focus'] as List).map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${f.toString()}',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    )),
                  if (phase['expertTips'] != null) ...[
                    const Divider(height: 24),
                    Text(
                      phase['expertTips'].toString(),
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        itemCount: roadmap.length,
      ),
    );
  }

  Widget _buildModernTargetCard(BuildContext context, String score, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MỤC TIÊU CHINH PHỤC',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score ĐIỂM',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dự kiến về đích trong: $time',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePdfExport(BuildContext context) async {
    final viewModel = context.read<AiTimelineViewModel>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final dynamic pdfData = await viewModel.exportPdf(assessment.id);
      
      if (!context.mounted) return;
      Navigator.pop(context);

      if (pdfData is Uint8List) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfBytes: pdfData,
              title: 'Lộ trình - ${assessment.title}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải PDF. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}
