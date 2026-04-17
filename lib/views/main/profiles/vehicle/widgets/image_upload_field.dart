import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_now_khoaluan/controllers/vehicle_profile_controller.dart';

/// Widget chọn + preview ảnh (từ gallery hoặc camera)
class ImageUploadField extends StatelessWidget {
  final String label;
  final String imageType; // key: vehiclePhoto, platePhoto, etc.
  final VehicleProfileController controller;
  final bool enabled;

  const ImageUploadField({
    super.key,
    required this.label,
    required this.imageType,
    required this.controller,
    this.enabled = true,
  });

  static const _primary = Color(0xFF1C64F2);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final url = controller.getImageUrl(imageType);
          final isUploading = controller.isUploadingImage(imageType);

          return GestureDetector(
            onTap: enabled && !isUploading
                ? () => _showPickOptions(context)
                : null,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? _primary.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: isUploading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Đang tải lên...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primary,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              if (enabled)
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: enabled
                                  ? _primary.withOpacity(0.5)
                                  : Colors.grey.shade300,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              enabled ? 'Chạm để chọn ảnh' : 'Chưa có ảnh',
                              style: TextStyle(
                                color: enabled
                                    ? const Color(0xFF64748B)
                                    : Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
            ),
          );
        }),
      ],
    );
  }

  /// Hiển thị bottom sheet chọn nguồn ảnh
  void _showPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn nguồn ảnh',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: _primary),
                ),
                title: const Text('Thư viện ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickAndUploadImage(imageType);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: _primary),
                ),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  controller.takeAndUploadPhoto(imageType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
