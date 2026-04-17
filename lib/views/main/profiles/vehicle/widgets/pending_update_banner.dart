import 'package:flutter/material.dart';

import 'package:ride_now_khoaluan/models/vehicle_profile_model.dart';

/// Banner thông báo trạng thái pending_review hoặc rejected
class PendingUpdateBanner extends StatelessWidget {
  final ProfileStatus status;
  final String? rejectionReason;

  const PendingUpdateBanner({
    super.key,
    required this.status,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ProfileStatus.approved) {
      return const SizedBox.shrink();
    }

    final bool isPending = status == ProfileStatus.pending_review;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.orange.shade200
              : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPending ? Icons.hourglass_top : Icons.warning_amber_rounded,
            color: isPending ? Colors.orange.shade700 : Colors.red.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending
                      ? 'Đang chờ duyệt'
                      : 'Yêu cầu bị từ chối',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isPending
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'Bạn đang có yêu cầu cập nhật chờ duyệt. Thông tin hiện tại vẫn đang được sử dụng cho các chuyến đi.'
                      : rejectionReason ?? 'Yêu cầu cập nhật hồ sơ đã bị từ chối. Vui lòng kiểm tra và gửi lại.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPending
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
