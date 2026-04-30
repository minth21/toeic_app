import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/class_material.dart';
import '../viewmodels/class_material_viewmodel.dart';
import '../../../theme/app_typography.dart';
import 'pdf_viewer_screen.dart';

class ClassMaterialsScreen extends StatefulWidget {
  const ClassMaterialsScreen({super.key});

  @override
  State<ClassMaterialsScreen> createState() => _ClassMaterialsScreenState();
}

class _ClassMaterialsScreenState extends State<ClassMaterialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      context.read<ClassMaterialViewModel>().loadMaterials(
        authVM.currentUser?.classId,
        authVM.token,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'LỚP HỌC CỦA TÔI',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.school_rounded,
                            size: 150,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 4, color: AppColors.primary),
                      insets: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'TÀI LIỆU'),
                      Tab(text: 'BÀI TẬP'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Consumer<ClassMaterialViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.ui(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final materials = viewModel.materials.where((m) => m.category == MaterialCategory.material).toList();
              final homeworks = viewModel.materials.where((m) => m.category == MaterialCategory.homework).toList();

              return TabBarView(
                children: [
                  _buildList(materials, 'Hiện chưa có tài liệu nào cho lớp này'),
                  _buildList(homeworks, 'Chưa có bài tập về nhà nào được giao'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ClassMaterial> items, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.indigo50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMsg,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _MaterialCard(material: items[index]);
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _MaterialCard extends StatelessWidget {
  final ClassMaterial material;
  const _MaterialCard({required this.material});

  String _formatDateString(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.softShadow,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleOpen(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(context),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  material.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (material.isCompleted)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (material.description != null && material.description!.isNotEmpty) ...[
                            Text(
                              material.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateString(material.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.indigo50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  material.type.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    Color color;
    Color bgColor;
    IconData icon;
    switch (material.type) {
      case ClassMaterialType.pdf:
        color = Colors.redAccent;
        bgColor = Colors.redAccent.withValues(alpha: 0.1);
        icon = Icons.picture_as_pdf_rounded;
        break;
      case ClassMaterialType.video:
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        icon = Icons.play_circle_fill;
        break;
      case ClassMaterialType.link:
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        icon = Icons.link_rounded;
        break;
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  void _handleOpen(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final materialVM = context.read<ClassMaterialViewModel>();

    // Mark as completed in background
    if (!material.isCompleted) {
      materialVM.completeMaterial(material.id, authVM.token!);
    }

    if (material.type == ClassMaterialType.video) {
      final videoId = YoutubePlayer.convertUrlToId(material.url);
      if (videoId != null) {
        _showVideoDialog(context, videoId);
        return;
      }
    }

    final uri = Uri.parse(material.url);
    if (await canLaunchUrl(uri)) {
      if (material.type == ClassMaterialType.pdf) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                title: material.title,
                url: material.url,
              ),
            ),
          );
        }
        return;
      }

      await launchUrl(
        uri,
        mode: material.type == ClassMaterialType.video
            ? LaunchMode.externalApplication
            : LaunchMode.inAppBrowserView,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết này')),
        );
      }
    }
  }

  void _showVideoDialog(BuildContext context, String videoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _YoutubePlayerDialog(videoId: videoId, title: material.title),
    );
  }
}

class _YoutubePlayerDialog extends StatefulWidget {
  final String videoId;
  final String title;
  const _YoutubePlayerDialog({required this.videoId, required this.title});

  @override
  State<_YoutubePlayerDialog> createState() => _YoutubePlayerDialogState();
}

class _YoutubePlayerDialogState extends State<_YoutubePlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header for Video Player
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              topActions: <Widget>[
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _controller.metadata.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              onReady: () {
                _controller.unMute();
                _controller.setVolume(100);
              },
            ),
            const Spacer(),
            // Extra info or controls can be added here
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Mẹo: Bạn có thể xoay ngang màn hình để xem video toàn cảnh.\nHãy kiểm tra âm lượng thiết bị nếu không nghe thấy tiếng.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _VideoPreview class removed as it is replaced by _YoutubePlayerDialog
