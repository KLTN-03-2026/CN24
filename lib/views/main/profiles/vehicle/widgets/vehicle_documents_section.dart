import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_now_khoaluan/controllers/vehicle_profile_controller.dart';
import 'image_upload_field.dart';
import 'section_header.dart';

/// Section giấy tờ xe: Đăng ký xe, Bảo hiểm, Ảnh giấy tờ
class VehicleDocumentsSection extends StatelessWidget {
  final VehicleProfileController controller;

  const VehicleDocumentsSection({super.key, required this.controller});

  static const _primary = Color(0xFF1C64F2);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditingDocuments.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'GIẤY TỜ XE',
            icon: Icons.description_outlined,
            isEditing: isEditing,
            onToggleEdit: () =>
                controller.isEditingDocuments.value = !isEditing,
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
                // Số đăng ký xe
                _buildTextField(
                  label: 'Số đăng ký xe',
                  value: controller.registrationNumber.value,
                  onChanged: (v) => controller.registrationNumber.value = v,
                  enabled: isEditing,
                  icon: Icons.article_outlined,
                ),
                const SizedBox(height: 16),

                // Ngày hết hạn đăng ký
                _buildTextField(
                  label: 'Hết hạn đăng ký (dd/MM/YYYY)',
                  value: controller.registrationExpiry.value,
                  onChanged: (v) => controller.registrationExpiry.value = v,
                  enabled: isEditing,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 16),

                // Số bảo hiểm
                _buildTextField(
                  label: 'Số bảo hiểm xe',
                  value: controller.insuranceNumber.value,
                  onChanged: (v) => controller.insuranceNumber.value = v,
                  enabled: isEditing,
                  icon: Icons.security_outlined,
                ),
                const SizedBox(height: 16),

                // Ngày hết hạn bảo hiểm
                _buildTextField(
                  label: 'Hết hạn bảo hiểm (dd/MM/YYYY)',
                  value: controller.insuranceExpiry.value,
                  onChanged: (v) => controller.insuranceExpiry.value = v,
                  enabled: isEditing,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 20),

                // Ảnh giấy đăng ký xe & Ảnh bảo hiểm
                Row(
                  children: [
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh đăng ký xe',
                        imageType: 'registrationPhoto',
                        controller: controller,
                        enabled: isEditing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh bảo hiểm xe',
                        imageType: 'insurancePhoto',
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
            fillColor:
                enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
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
