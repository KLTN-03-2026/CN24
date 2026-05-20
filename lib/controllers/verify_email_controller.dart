import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class VerifyEmailController extends GetxController {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _timer;
  final RxBool isEmailVerified = false.obs;
  final RxBool canResendEmail = true.obs;

  @override
  void onInit() {
    super.onInit();
    isEmailVerified.value = _auth.currentUser?.emailVerified ?? false;
    
    if (!isEmailVerified.value) {
      _sendVerificationEmail();
      
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _checkEmailVerified() async {
    try {
      await _authService.reloadUser();
      isEmailVerified.value = _auth.currentUser?.emailVerified ?? false;

      if (isEmailVerified.value) {
        _timer?.cancel();
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      debugPrint('[VerifyEmailController] Error reloading user: $e');
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      debugPrint('[VerifyEmailController] Error sending email: $e');
      Get.snackbar('Lỗi', 'Không thể gửi email xác nhận. Vui lòng thử lại sau.');
    }
  }

  Future<void> resendVerificationEmail() async {
    if (canResendEmail.value) {
      await _sendVerificationEmail();
      Get.snackbar('Thành công', 'Đã gửi lại email xác nhận!');
      
      canResendEmail.value = false;
      await Future.delayed(const Duration(seconds: 30));
      canResendEmail.value = true;
    } else {
      Get.snackbar('Thông báo', 'Vui lòng đợi 30 giây để gửi lại email.');
    }
  }

  Future<void> logOut() async {
    _timer?.cancel();
    await _authService.logOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
