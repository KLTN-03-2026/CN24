import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/complaint_model.dart';
import '../../../models/trip_model.dart';
import '../../../repositories/ride_repository.dart';

class SubmitComplaintView extends StatefulWidget {
  final TripModel? trip;

  const SubmitComplaintView({super.key, this.trip});

  @override
  State<SubmitComplaintView> createState() => _SubmitComplaintViewState();
}

class _SubmitComplaintViewState extends State<SubmitComplaintView> {
  final AuthController _authController = Get.find<AuthController>();
  final RideRepository _rideRepository = RideRepository();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedReason;
  bool _isSubmitting = false;
  final List<File> _selectedFiles = [];

  final List<String> _reasons = [
    'Thái độ tài xế / khách hàng không tốt',
    'Chạy ẩu / Không tuân thủ luật',
    'Xe không đúng với thông tin',
    'Vấn đề về thanh toán / Giá cước',
    'Hành vi quấy rối / Thiếu lịch sự',
    'Ứng dụng gặp lỗi kỹ thuật',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _descController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _pickImage() async {
    if (_selectedFiles.length >= 5) {
      Get.snackbar('Thông báo', 'Tối đa chỉ được chọn 5 file',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFiles.add(File(image.path));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (_selectedReason == null) {
      Get.snackbar('Thông báo', 'Vui lòng chọn danh mục khiếu nại',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (desc.isEmpty) {
      Get.snackbar('Thông báo', 'Vui lòng nhập chi tiết sự cố',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _authController.userModel;
      if (user == null) throw Exception('Vui lòng đăng nhập lại.');

      // 1. Upload files lên Storage nếu có
      List<String> imageUrls = [];
      if (_selectedFiles.isNotEmpty) {
        imageUrls = await _rideRepository.uploadFiles(_selectedFiles, 'complaints/${user.id}');
      }

      String? targetUserId;
      if (widget.trip != null) {
        targetUserId = user.id == widget.trip!.driverId
            ? widget.trip!.customerId
            : widget.trip!.driverId;
      }

      final complaintId = 'comp_${DateTime.now().millisecondsSinceEpoch}';

      final complaint = ComplaintModel(
        id: complaintId,
        tripId: widget.trip?.id ?? 'GENERAL',
        userId: user.id,
        userRole: user.role.name,
        targetUserId: targetUserId,
        reason: _selectedReason!,
        description: desc,
        status: 'pending',
        images: imageUrls,
        createdAt: DateTime.now(),
      );

      await _rideRepository.submitComplaint(complaint);

      Get.back();
      Get.snackbar('Thành công', 'Chúng tôi đã nhận được yêu cầu và sẽ phản hồi sớm.',
          backgroundColor: const Color(0xFF0061A4), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể gửi khiếu nại: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0061A4);
    const borderGrey = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Support & Complaints',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderGrey, height: 1.0),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh mục khiếu nại',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGrey, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Chọn vấn đề bạn gặp phải',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  value: _selectedReason,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                  items: _reasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Chi tiết sự cố',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 6,
              maxLength: 500,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Vui lòng mô tả chi tiết vấn đề của bạn để chúng tôi có thể hỗ trợ tốt nhất...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
                filled: true,
                fillColor: Colors.white,
                counterText: '', 
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderGrey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderGrey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${_descController.text.length}/500 ký tự',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hình ảnh / Video đính kèm (Tùy chọn)',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _buildDashedUploadButton(),
                  ),
                  const SizedBox(width: 16),
                  ...List.generate(_selectedFiles.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildImagePreview(index),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hỗ trợ định dạng JPG, PNG, MP4. Tối đa 5 file.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'Gửi Yêu Cầu',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Chúng tôi sẽ phản hồi trong vòng 24 giờ làm việc.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedUploadButton() {
    return CustomPaint(
      painter: DashedRectPainter(color: const Color(0xFFCBD5E1)),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0061A4), size: 28),
            const SizedBox(height: 8),
            const Text('Thêm ảnh',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            image: DecorationImage(
              image: FileImage(_selectedFiles[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) => false;
}
