import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/verify_email_controller.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF3F5F8);
  static const _textDark = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(VerifyEmailController());
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'email của bạn';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Xác nhận Email',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_rounded,
              size: 100,
              color: _primary,
            ),
            const SizedBox(height: 32),
            const Text(
              'Kiểm tra hộp thư của bạn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Chúng tôi đã gửi một email xác nhận đến địa chỉ:\n$email\n\nVui lòng kiểm tra hộp thư đến (hoặc thư rác) và nhấn vào đường link để xác nhận tài khoản.',
              style: const TextStyle(
                fontSize: 16,
                color: _textSoft,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.canResendEmail.value
                        ? () => controller.resendVerificationEmail()
                        : null,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      controller.canResendEmail.value
                          ? 'Gửi lại Email'
                          : 'Đang chờ...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: const Color(0xFFE6EAF0),
                    ),
                  )),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => controller.logOut(),
              child: const Text(
                'Quay lại Đăng nhập',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang chờ xác nhận...',
              style: TextStyle(
                color: _textSoft,
              ),
            )
          ],
        ),
      ),
    );
  }
}
