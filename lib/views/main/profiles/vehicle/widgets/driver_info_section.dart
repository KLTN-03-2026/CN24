import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_now_khoaluan/controllers/vehicle_profile_controller.dart';
import 'image_upload_field.dart';
import 'section_header.dart';

/// Section thông tin tài xế: Họ tên, SĐT, Avatar, GPLX, CCCD
class DriverInfoSection extends StatelessWidget {
  final VehicleProfileController controller;

  const DriverInfoSection({super.key, required this.controller});

  static const _primary = Color(0xFF1C64F2);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditingDriverInfo.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'THÔNG TIN TÀI XẾ',
            icon: Icons.person_outline,
            isEditing: isEditing,
            onToggleEdit: () =>
                controller.isEditingDriverInfo.value = !isEditing,
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTextField(
                  label: 'Họ và tên',
                  value: controller.fullName.value,
                  onChanged: (v) => controller.fullName.value = v,
                  enabled: isEditing,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Số điện thoại',
                  value: controller.phoneNumber.value,
                  onChanged: (v) => controller.phoneNumber.value = v,
                  enabled: isEditing,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Số GPLX',
                  value: controller.driverLicenseNumber.value,
                  onChanged: (v) => controller.driverLicenseNumber.value = v,
                  enabled: isEditing,
                  icon: Icons.credit_card_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Hết hạn GPLX (dd/MM/YYYY)',
                  value: controller.driverLicenseExpiry.value,
                  onChanged: (v) => controller.driverLicenseExpiry.value = v,
                  enabled: isEditing,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'CCCD / CMND',
                  value: controller.nationalId.value,
                  onChanged: (v) => controller.nationalId.value = v,
                  enabled: isEditing,
                  icon: Icons.perm_identity,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                // Ảnh đại diện & Ảnh GPLX
                Row(
                  children: [
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh đại diện',
                        imageType: 'avatar',
                        controller: controller,
                        enabled: isEditing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh GPLX',
                        imageType: 'driverLicensePhoto',
                        controller: controller,
                        enabled: isEditing,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required bool enabled,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? _textDark : const Color(0xFF64748B),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _primary, size: 18),
            filled: true,
            fillColor: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
