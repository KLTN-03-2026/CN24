import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';


class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  String? _nameError;
  String? _phoneError;
  bool _isEditing = false;
  bool _isSaving = false;

  late Worker _userModelWorker;

  @override
  void initState() {
    super.initState();
    // Set giá trị ban đầu nếu userModel đã sẵn sàng
    _nameController.text = _authController.userModel?.name ?? '';
    _phoneController.text = _authController.userModel?.phone ?? '';

    // Lắng nghe thay đổi userModel từ Firestore stream
    // để cập nhật khi dữ liệu được load bất đồng bộ
    _userModelWorker = ever(_authController.userModelRx, (userModel) {
      if (!_isEditing && userModel != null) {
        final newName = userModel.name;
        final newPhone = userModel.phone ?? '';
        if (_nameController.text != newName) {
          _nameController.text = newName;
        }
        if (_phoneController.text != newPhone) {
          _phoneController.text = newPhone;
        }
      }
    });
  }

  @override
  void dispose() {
    _userModelWorker.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      _authController.updateAvatar(File(image.path));
    }
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validation
    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'name_empty_error'.tr);
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }

    if (phone.isEmpty) {
      setState(() => _phoneError = 'phone_empty_error'.tr);
      hasError = true;
    } else if (!RegExp(r'^\+?[0-9\s]{9,15}$').hasMatch(phone)) {
      setState(() => _phoneError = 'phone_invalid_error'.tr);
      hasError = true;
    } else {
      setState(() => _phoneError = null);
    }

    if (hasError) return;

    setState(() {
      _isEditing = false;
      _isSaving = true;
    });

    await _authController.updateProfile(name: name, phone: phone);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'profile'.tr,
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Obx(() {
        final user = _authController.userModel;
        if (user == null) {
          return const Center(child: Text('Chưa đăng nhập'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- AVATAR & INFO HEADER ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.blue.shade50,
                        image: DecorationImage(
                          image: NetworkImage(
                            user.avatar ??
                                'https://hoanghamobile.com/tin-tuc/wp-content/uploads/2024/05/anh-cho-hai-1.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  _nameFocusNode.requestFocus();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _nameController,
                      builder: (context, value, child) {
                        return Text(
                          _nameController.text.isEmpty
                              ? 'no_name'.tr
                              : _nameController.text,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 18, color: theme.primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),

              // Verified Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'verified'.tr,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- PERSONAL INFORMATION SECTION ---
              _buildSectionTitle(context, 'account_settings'.tr),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'full_name'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      onChanged: (val) {
                        if (!_isEditing) setState(() => _isEditing = true);
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'enter_name'.tr,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_nameError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _nameError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'phone_number'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) {
                        if (!_isEditing) setState(() => _isEditing = true);
                        if (_phoneError != null) setState(() => _phoneError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'enter_phone'.tr,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (_phoneError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _phoneError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isEditing && !_isSaving ? _saveProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: theme.primaryColor.withOpacity(0.6),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'save_changes'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),

    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
