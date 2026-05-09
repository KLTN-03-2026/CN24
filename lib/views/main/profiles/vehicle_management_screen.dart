import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/views/main/profiles/driver_vehicle_screen.dart';

class VehicleManagementScreen extends StatelessWidget {
  const VehicleManagementScreen({super.key});

  static const _primary = Color(0xFF1C64F2);
  static const _bg = Color(0xFFF8FAFC);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : _bg,
      appBar: AppBar(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : _bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : _textDark, size: 20),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'vehicle_info'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildManagementItem(
              context,
              icon: Icons.person_outline,
              title: 'driver_info'.tr,
              subtitle: 'Cập nhật họ tên, số điện thoại, CCCD',
              onTap: () => Get.to(() => const DriverVehicleScreen(initialSection: 0)),
            ),
            const SizedBox(height: 16),
            _buildManagementItem(
              context,
              icon: Icons.directions_car_outlined,
              title: 'vehicle_info'.tr,
              subtitle: 'Quản lý thông tin xe và giấy tờ xe',
              onTap: () => Get.to(() => const DriverVehicleScreen(initialSection: 1)),
            ),
            const SizedBox(height: 16),
            _buildManagementItem(
              context,
              icon: Icons.badge_outlined,
              title: 'license_info'.tr,
              subtitle: 'Cập nhật thông tin bằng lái xe',
              onTap: () => Get.to(() => const DriverVehicleScreen(initialSection: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
