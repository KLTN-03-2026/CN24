import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_now_khoaluan/controllers/vehicle_profile_controller.dart';
import 'image_upload_field.dart';
import 'section_header.dart';

/// Section thông tin xe: Biển số, Loại xe, Hãng, Model, Màu, Năm SX, Số chỗ, Ảnh
class VehicleInfoSection extends StatelessWidget {
  final VehicleProfileController controller;

  const VehicleInfoSection({super.key, required this.controller});

  static const _primary = Color(0xFF1C64F2);
  static const _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditingVehicleInfo.value;
      final isBike = controller.vehicleType.value == 'Bike';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'THÔNG TIN XE',
            icon: Icons.directions_car_outlined,
            isEditing: isEditing,
            onToggleEdit: () =>
                controller.isEditingVehicleInfo.value = !isEditing,
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
                // Biển số xe (bắt buộc)
                _buildTextField(
                  label: 'Biển số xe *',
                  value: controller.licensePlate.value,
                  onChanged: (v) => controller.licensePlate.value = v,
                  enabled: isEditing,
                  icon: Icons.confirmation_number_outlined,
                ),
                const SizedBox(height: 16),

                // Loại xe (dropdown)
                _buildVehicleTypeSelector(isEditing),
                const SizedBox(height: 16),

                // Hãng xe
                _buildTextField(
                  label: 'Hãng xe',
                  value: controller.brand.value,
                  onChanged: (v) => controller.brand.value = v,
                  enabled: isEditing,
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),

                // Dòng xe / Model
                _buildTextField(
                  label: 'Dòng xe / Model',
                  value: controller.model.value,
                  onChanged: (v) => controller.model.value = v,
                  enabled: isEditing,
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),

                // Màu xe
                _buildTextField(
                  label: 'Màu xe',
                  value: controller.color.value,
                  onChanged: (v) => controller.color.value = v,
                  enabled: isEditing,
                  icon: Icons.palette_outlined,
                ),
                const SizedBox(height: 16),

                // Năm sản xuất
                _buildTextField(
                  label: 'Năm sản xuất',
                  value: controller.year.value,
                  onChanged: (v) => controller.year.value = v,
                  enabled: isEditing,
                  icon: Icons.date_range_outlined,
                  keyboardType: TextInputType.number,
                ),

                // Số chỗ ngồi — ẩn khi Bike
                if (!isBike) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Số chỗ ngồi',
                    value: controller.seatCount.value,
                    onChanged: (v) => controller.seatCount.value = v,
                    enabled: isEditing,
                    icon: Icons.event_seat_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 20),

                // Ảnh xe & Ảnh biển số
                Row(
                  children: [
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh xe',
                        imageType: 'vehiclePhoto',
                        controller: controller,
                        enabled: isEditing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ImageUploadField(
                        label: 'Ảnh biển số',
                        imageType: 'platePhoto',
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

  /// Dropdown chọn loại xe (Car / Bike)
  Widget _buildVehicleTypeSelector(bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại xe',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: enabled
                ? null
                : Border.all(color: Colors.grey.shade200, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.vehicleType.value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: enabled ? _primary : Colors.grey,
              ),
              items: const [
                DropdownMenuItem(value: 'Car', child: Text('🚗  Ô tô (Car)')),
                DropdownMenuItem(
                    value: 'Bike', child: Text('🏍️  Xe máy (Bike)')),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        controller.vehicleType.value = value;
                        // Xóa seatCount nếu chuyển sang Bike
                        if (value == 'Bike') {
                          controller.seatCount.value = '';
                        }
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
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
