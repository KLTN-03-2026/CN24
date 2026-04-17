import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_now_khoaluan/controllers/vehicle_profile_controller.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle/widgets/driver_info_section.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle/widgets/pending_update_banner.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle/widgets/vehicle_documents_section.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle/widgets/vehicle_info_section.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle/widgets/vehicle_status_badge.dart';

/// Màn hình quản lý hồ sơ xe của tài xế
/// Giao diện tham khảo phong cách Grab Driver
class DriverVehicleScreen extends StatelessWidget {
  const DriverVehicleScreen({super.key});

  static const _primary = Color(0xFF1C64F2);
  static const _bg = Color(0xFFF8FAFC);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    // Đăng ký controller khi vào màn hình, tự dispose khi rời
    final controller = Get.put(VehicleProfileController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 20),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          'Thông tin xe',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Badge trạng thái ở AppBar
          Obx(() {
            final profile = controller.profile.value;
            if (profile == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: VehicleStatusBadge(status: profile.status),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _primary),
                SizedBox(height: 16),
                Text(
                  'Đang tải thông tin...',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Error state
        if (controller.errorMessage.value.isNotEmpty &&
            controller.profile.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.fetchProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Nội dung scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner pending/rejected
                    Obx(() {
                      final profile = controller.profile.value;
                      if (profile == null) return const SizedBox.shrink();
                      return PendingUpdateBanner(
                        status: profile.status,
                        rejectionReason: profile.rejectionReason,
                      );
                    }),

                    // Section 1: Thông tin tài xế
                    DriverInfoSection(controller: controller),
                    const SizedBox(height: 24),

                    // Section 2: Thông tin xe
                    VehicleInfoSection(controller: controller),
                    const SizedBox(height: 24),

                    // Section 3: Giấy tờ xe
                    VehicleDocumentsSection(controller: controller),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom: Nút Lưu thay đổi (fixed ở bottom)
            _buildSaveButton(controller),
          ],
        );
      }),
    );
  }

  /// Nút lưu thay đổi ở bottom
  Widget _buildSaveButton(VehicleProfileController controller) {
    return Obx(() {
      final isSaving = controller.isSaving.value;
      final isAnyEditing = controller.isEditingDriverInfo.value ||
          controller.isEditingVehicleInfo.value ||
          controller.isEditingDocuments.value;

      // Ẩn nút khi không có section nào đang edit
      // Trừ khi chưa có profile (lần đầu tạo)
      final showButton = isAnyEditing || controller.profile.value == null;

      if (!showButton) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isSaving ? null : () => controller.saveProfile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: _primary.withOpacity(0.6),
              disabledForegroundColor: Colors.white,
            ),
            child: isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Đang lưu...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}
