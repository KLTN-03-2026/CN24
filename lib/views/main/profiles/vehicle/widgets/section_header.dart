import 'package:flutter/material.dart';

/// Header chung cho mỗi section: tiêu đề + nút Chỉnh sửa
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isEditing;
  final VoidCallback onToggleEdit;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.isEditing,
    required this.onToggleEdit,
  });

  static const _primary = Color(0xFF1C64F2);
  static const _textSoft = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEditing ? _primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEditing ? _primary : _textSoft.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isEditing ? 'Đang sửa' : 'Chỉnh sửa',
                style: TextStyle(
                  color: isEditing ? _primary : _textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
