import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/class_material.dart';
import '../viewmodels/class_material_viewmodel.dart';
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
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Lớp học của tôi', 
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: false,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Tài liệu', icon: Icon(Icons.book_outlined)),
              Tab(text: 'Bài tập', icon: Icon(Icons.edit_note_outlined)),
            ],
          ),
        ),
        body: Consumer<ClassMaterialViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(viewModel.errorMessage!, textAlign: TextAlign.center),
              ));
            }

            final materials = viewModel.materials.where((m) => m.category == MaterialCategory.material).toList();
            final homeworks = viewModel.materials.where((m) => m.category == MaterialCategory.homework).toList();

            return TabBarView(
              children: [
                _buildList(materials, 'Lớp chưa có tài liệu nào'),
                _buildList(homeworks, 'Chưa có bài tập về nhà nào'),
              ],
            );
          },
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
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(emptyMsg, 
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _MaterialCard(material: items[index]);
      },
    );
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
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
                          Text(
                            material.title, 
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, 
                              fontSize: 16, 
                              letterSpacing: -0.3,
                              color: Theme.of(context).textTheme.titleMedium?.color
                            )
                          ),
                          const SizedBox(height: 4),
                          if (material.description != null && material.description!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                material.description!, 
                                maxLines: 2, 
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color
                                )
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateString(material.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Center(
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  void _handleOpen(BuildContext context) async {
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
      
      // Use inAppBrowserView to keep user inside the app for Links
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
      builder: (context) => _YoutubePlayerDialog(videoId: videoId),
    );
  }
}

class _YoutubePlayerDialog extends StatefulWidget {
  final String videoId;
  const _YoutubePlayerDialog({required this.videoId});

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
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              onReady: () {
                // Ensure audio focus etc. if needed
              },
            ),
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Đóng', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// _VideoPreview class removed as it is replaced by _YoutubePlayerDialog
