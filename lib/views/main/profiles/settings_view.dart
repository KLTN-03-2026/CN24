import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';
import 'package:ride_now_khoaluan/routes/app_routes.dart';
import 'package:ride_now_khoaluan/views/main/profiles/driver_vehicle_screen.dart';
import 'package:ride_now_khoaluan/views/main/profiles/my_complaints_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/support_center_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/vehicle_management_screen.dart';
import 'package:ride_now_khoaluan/views/main/trips/submit_complaint_view.dart';
import 'package:ride_now_khoaluan/controllers/settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final settingsController = Get.find<SettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Obx(() {
        final user = authController.userModel;
        if (user == null) {
          return const Center(child: Text('Chưa đăng nhập'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ACCOUNT SETTINGS SECTION ---
              _buildSectionTitle(context, 'account_settings'.tr),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                        context,
                        icon: Icons.directions_car_outlined,
                        title: 'vehicle_info'.tr,
                        onTap: () => Get.to(() => const VehicleManagementScreen()),
                      ),
                      _buildDivider(context),
                    ],
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'change_password'.tr,
                      onTap: () => Get.toNamed(AppRoutes.changePassword),
                    ),
                    _buildDivider(context),
                    if (user.role != UserRole.customer) ...[
                      _buildSettingsItem(
                        context,
                        icon: Icons.payments_outlined,
                        title: 'payment_methods'.tr,
                        onTap: () {},
                      ),
                      _buildDivider(context),
                    ],
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'support'.tr,
                      onTap: () => Get.to(() => const SupportCenterView()),
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.report_problem_outlined,
                      title: 'submit_complaint'.tr,
                      onTap: () => Get.to(() => const SubmitComplaintView()),
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'my_complaints'.tr,
                      onTap: () => Get.to(() => const MyComplaintsView()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- APP SETTINGS SECTION ---
              _buildSectionTitle(context, 'app_settings'.tr),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.language,
                      title: 'language'.tr,
                      onTap: () => _showLanguageDialog(context),
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'theme'.tr,
                      onTap: () => _showThemeDialog(context),
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
                    authController.logOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    'logout'.tr,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFFEF2F2),
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'choose_language'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogItem(
              context,
              title: 'Tiếng Việt',
              isSelected: Get.find<SettingsController>().language == 'vi',
              onTap: () {
                Get.find<SettingsController>().updateLanguage('vi');
                Get.back();
              },
            ),
            _buildDivider(context),
            _buildDialogItem(
              context,
              title: 'English',
              isSelected: Get.find<SettingsController>().language == 'en',
              onTap: () {
                Get.find<SettingsController>().updateLanguage('en');
                Get.back();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'theme'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogItem(
              context,
              title: 'light'.tr,
              icon: Icons.light_mode_outlined,
              isSelected: Get.find<SettingsController>().theme != 'dark',
              onTap: () {
                Get.find<SettingsController>().updateTheme('light');
                Get.back();
              },
            ),
            _buildDivider(context),
            _buildDialogItem(
              context,
              title: 'dark'.tr,
              icon: Icons.dark_mode_outlined,
              isSelected: Get.find<SettingsController>().theme == 'dark',
              onTap: () {
                Get.find<SettingsController>().updateTheme('dark');
                Get.back();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(
    BuildContext context, {
    required String title,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: icon != null ? Icon(icon, color: theme.colorScheme.onSurface) : null,
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : null,
    );
  }
}
