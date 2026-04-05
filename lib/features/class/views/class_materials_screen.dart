import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/class_material.dart';
import '../viewmodels/class_material_viewmodel.dart';

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
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildIcon(),
            title: Text(material.title, 
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            subtitle: material.description != null 
              ? Text(material.description!, maxLines: 2, overflow: TextOverflow.ellipsis) 
              : null,
            onTap: () => _handleOpen(context),
          ),
          if (material.type == ClassMaterialType.video)
            _VideoPreview(url: material.url),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    Color color;
    IconData icon;
    switch (material.type) {
      case ClassMaterialType.pdf:
        color = Colors.red.shade400;
        icon = Icons.picture_as_pdf;
        break;
      case ClassMaterialType.video:
        color = Colors.red;
        icon = Icons.play_circle_fill;
        break;
      case ClassMaterialType.link:
        color = Colors.blue.shade400;
        icon = Icons.link;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  void _handleOpen(BuildContext context) async {
    final uri = Uri.parse(material.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết này')),
        );
      }
    }
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.url) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
        ),
      ),
    );
  }
}
