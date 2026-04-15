import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'shimmer_loading.dart'; // Đảm bảo bạn đã import đúng widget ShimmerLoading

class AIEvaluationCard extends StatefulWidget {
  final String? htmlContent;
  final int score;
  final bool isLoading;
  final VoidCallback onReview; // Hàm khi bấm Xem lại
  final VoidCallback onExit; // Hàm khi bấm Thoát
  final VoidCallback onDoTest; // Hàm khi bấm Làm bài

  const AIEvaluationCard({
    super.key,
    this.htmlContent,
    required this.score,
    required this.isLoading,
    required this.onReview,
    required this.onExit,
    required this.onDoTest,
  });

  @override
  State<AIEvaluationCard> createState() => _AIEvaluationCardState();
}

class _AIEvaluationCardState extends State<AIEvaluationCard> {
  // 1. Tạo bộ điều khiển cuộn
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant AIEvaluationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 2. Logic Tự Động Cuộn:
    // Nếu trạng thái chuyển từ "Đang tải" (true) sang "Đã xong" (false)
    if (oldWidget.isLoading == true && widget.isLoading == false) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Đợi 500ms để UI vẽ xong nội dung HTML dài 1000 từ rồi mới cuộn
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Cuộn xuống tận cùng
          duration: const Duration(
            milliseconds: 800,
          ), // Thời gian trượt (0.8 giây)
          curve: Curves.easeOutQuart, // Hiệu ứng trượt mượt mà
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Giải phóng bộ nhớ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Xử lý dữ liệu JSON
    Map<String, dynamic> apiResponse = {};
    if (widget.htmlContent != null && !widget.isLoading) {
      try {
        apiResponse = jsonDecode(widget.htmlContent!);
      } catch (e) {
        apiResponse['assessment'] = widget.htmlContent;
        apiResponse['progressScore'] = widget.score;
      }
    }

    // 4. HIỆN SHIMMER (DUY NHẤT 1 CÁI) KHI ĐANG TẢI
    if (widget.isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerLoading.circular(width: 120, height: 120), // Giả lập biểu đồ
            SizedBox(height: 24),
            ShimmerLoading.rectangular(
              height: 20,
              width: 200,
            ), // Giả lập tiêu đề
            SizedBox(height: 12),
            ShimmerLoading.rectangular(height: 150), // Giả lập nội dung dài
            SizedBox(height: 24),
            ShimmerLoading.rectangular(height: 50), // Giả lập nút bấm
          ],
        ),
      );
    }

    // 5. HIỆN NỘI DUNG CHÍNH (KHI TẢI XONG)
    return Column(
      children: [
        // A. BIỂU ĐỒ TRÒN
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularPercentIndicator(
            radius: 75.0,
            lineWidth: 14.0,
            animation: true,
            percent: (apiResponse['progressScore'] ?? widget.score) / 100.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${apiResponse['progressScore'] ?? widget.score}%",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                  ),
                ),
                const Text(
                  "Chính xác",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            progressColor: Colors.blueAccent,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ),

        // B. NỘI DUNG CÓ THANH CUỘN (GẮN CONTROLLER VÀO ĐÂY)
        Container(
          height: 380, // Chiều cao cố định
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController, // Gắn bộ điều khiển
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _scrollController, // Gắn bộ điều khiển vào View
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: HtmlWidget(
                  apiResponse['assessment'] ?? "",
                  textStyle: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'h1' ||
                        element.localName == 'h2' ||
                        element.localName == 'h3') {
                      return {'font-size': '18px', 'font-weight': 'bold'};
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),

        // C. NÚT BẤM
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              // 1. Nút Thoát (Trái)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onExit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Thoát",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 2. Nút Xem lại (Giữa)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReview,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Xem lại",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 3. Nút Làm bài (Phải)
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onDoTest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Làm bài",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
