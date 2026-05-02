import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../repositories/ride_repository.dart';

class RatingDialog extends StatefulWidget {
  final String rideId;
  final String driverId;
  final String driverName;
  final String notificationId;

  const RatingDialog({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.notificationId,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final TextEditingController _feedbackController = TextEditingController();
  final RideRepository _rideRepository = RideRepository();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đánh giá tài xế',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF223285)),
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn thấy chuyến đi cùng ${widget.driverName} thế nào?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập góp ý của bạn (không bắt buộc)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF223285)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF223285),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      await _rideRepository.submitRating(
        rideId: widget.rideId,
        driverId: widget.driverId,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
        notificationId: widget.notificationId,
      );
      Get.back();
      Get.snackbar(
        'Thành công',
        'Cảm ơn bạn đã đánh giá!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể gửi đánh giá: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
