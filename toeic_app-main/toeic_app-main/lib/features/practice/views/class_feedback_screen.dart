import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/feedback_viewmodel.dart';
import '../../../constants/app_constants.dart';

class ClassFeedbackScreen extends StatefulWidget {
  const ClassFeedbackScreen({super.key});

  @override
  State<ClassFeedbackScreen> createState() => _ClassFeedbackScreenState();
}

class _ClassFeedbackScreenState extends State<ClassFeedbackScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<FeedbackViewModel>().loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    final authViewModel = context.read<AuthViewModel>();
    final feedbackViewModel = context.read<FeedbackViewModel>();
    final user = authViewModel.currentUser;

    if (user?.classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa thuộc lớp học nào để gửi ý kiến')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung ý kiến')),
      );
      return;
    }

    final success = await feedbackViewModel.sendFeedback(
      classId: user!.classId!,
      content: _contentController.text.trim(),
    );

    if (success && mounted) {
      _contentController.clear();
      setState(() => _isExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi ý kiến thành công! Giáo viên sẽ sớm phản hồi.')),
      );
    } else if (feedbackViewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedbackViewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final teacherName = user?.teacherName ?? 'Giáo viên';
    final className = user?.className ?? 'Lớp học';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ý kiến Giáo viên'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.school, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lớp: $className',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Feedback Input Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Gửi ý kiến hoặc thắc mắc của bạn',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: _isExpanded ? 5 : 2,
                      onTap: () => setState(() => _isExpanded = true),
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung tại đây...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<FeedbackViewModel>(
                      builder: (context, vm, child) {
                        return ElevatedButton.icon(
                          onPressed: vm.isLoading ? null : _submitFeedback,
                          icon: vm.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send),
                          label: Text(vm.isLoading ? 'Đang gửi...' : 'Gửi cho giáo viên'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // History Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Lịch sử ý kiến',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<FeedbackViewModel>(
              builder: (context, vm, child) {
                if (vm.isLoading && vm.history.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.divider),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có ý kiến nào được gửi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: vm.history.length,
                  itemBuilder: (context, index) {
                    final item = vm.history[index];
                    final date = DateTime.parse(item['createdAt']);
                    final isResolved = item['status'] == 'RESOLVED';
                    final bool isFromTeacher = item['isFromTeacher'] ?? false;

                    if (isFromTeacher) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.primary, width: 0.5),
                        ),
                        color: AppColors.primary.withValues(alpha: 0.02),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.tips_and_updates_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lời khuyên từ Giáo viên',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(date),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Text(
                                item['content'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isResolved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isResolved ? 'Đã xử lý' : 'Đang chờ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isResolved ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['content'] ?? '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (item['teacherReply'] != null && item['teacherReply'].toString().isNotEmpty) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.comment_rounded, size: 14, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Phản hồi từ $teacherName:',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
                                ),
                                child: Text(
                                  item['teacherReply'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
