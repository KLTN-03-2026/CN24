import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';
import 'package:ride_now_khoaluan/routes/app_routes.dart';
import 'package:ride_now_khoaluan/views/main/profiles/driver_vehicle_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _phoneController = TextEditingController();

  String? _phoneError;
  bool _isEditingPhone = false;
  bool _isSavingPhone = false;

  static const _primary = Color(0xFF1C64F2); // Vibrant blue matching image
  static const _bg = Color(0xFFF8FAFC);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _phoneController.text = _authController.userModel?.phone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _savePhone() async {
    final phone = _phoneController.text.trim();

    // Validation
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number cannot be empty');
      return;
    }
    if (!RegExp(r'^\+?[0-9\s]{9,15}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Invalid phone number format');
      return;
    }

    setState(() {
      _phoneError = null;
      _isEditingPhone = false;
      _isSavingPhone = true;
    });

    await _authController.updateUserPhone(phone);

    if (mounted) {
      setState(() => _isSavingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        final user = _authController.userModel;
        if (user == null) {
          return const Center(child: Text('Not logged in'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- AVATAR & INFO HEADER ---
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.blue.shade50,
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://hoanghamobile.com/tin-tuc/wp-content/uploads/2024/05/anh-cho-hai-1.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _primary,
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
              const SizedBox(height: 16),

              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(fontSize: 15, color: _textSoft),
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
                      'Verified',
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
              _buildSectionTitle('PERSONAL INFORMATION'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) {
                        if (!_isEditingPhone)
                          setState(() => _isEditingPhone = true);
                        if (_phoneError != null)
                          setState(() => _phoneError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
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
                          borderSide: const BorderSide(
                            color: _primary,
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
                        onPressed:
                            (_isEditingPhone ||
                                    _phoneController.text.isEmpty) &&
                                !_isSavingPhone
                            ? _savePhone
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: _primary.withOpacity(0.6),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: _isSavingPhone
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- ACCOUNT SETTINGS SECTION ---
              _buildSectionTitle('ACCOUNT SETTINGS'),
              Container(
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
                    // Mục "Thông tin xe" — chỉ hiển thị cho Driver
                    if (user.role == UserRole.driver) ...[
                      _buildSettingsItem(
                        icon: Icons.directions_car,
                        title: 'Thông tin xe',
                        onTap: () => Get.to(() => const DriverVehicleScreen()),
                      ),
                      _buildDivider(),
                    ],
                    _buildSettingsItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () => Get.toNamed(AppRoutes.changePassword),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.payments_outlined,
                      title: 'Payment Methods',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.history,
                      title: 'Ride History',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Support',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _authController.logOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
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
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }
}
