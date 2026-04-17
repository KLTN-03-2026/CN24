import 'package:flutter/material.dart';

import 'package:ride_now_khoaluan/models/vehicle_profile_model.dart';

/// Badge hiển thị trạng thái hồ sơ xe: Đã duyệt / Chờ duyệt / Bị từ chối
class VehicleStatusBadge extends StatelessWidget {
  final ProfileStatus status;

  const VehicleStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _foregroundColor, size: 14),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (status) {
      case ProfileStatus.approved:
        return 'Đã duyệt';
      case ProfileStatus.pending_review:
        return 'Chờ duyệt';
      case ProfileStatus.rejected:
        return 'Bị từ chối';
    }
  }

  IconData get _icon {
    switch (status) {
      case ProfileStatus.approved:
        return Icons.check_circle;
      case ProfileStatus.pending_review:
        return Icons.access_time;
      case ProfileStatus.rejected:
        return Icons.cancel;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case ProfileStatus.approved:
        return Colors.green.shade50;
      case ProfileStatus.pending_review:
        return Colors.orange.shade50;
      case ProfileStatus.rejected:
        return Colors.red.shade50;
    }
  }

  Color get _foregroundColor {
    switch (status) {
      case ProfileStatus.approved:
        return Colors.green.shade700;
      case ProfileStatus.pending_review:
        return Colors.orange.shade700;
      case ProfileStatus.rejected:
        return Colors.red.shade700;
    }
  }
}
