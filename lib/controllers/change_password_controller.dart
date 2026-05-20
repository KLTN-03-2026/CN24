import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';

class ChangePasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;
  final RxBool _isSuccess = false.obs;

  bool get isLoading => _isLoading.value;

  String get error => _error.value;

  bool get obscureCurrentPassword => _obscureCurrentPassword.value;

  bool get obscureNewPassword => _obscureNewPassword.value;

  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  bool get isSuccess => _isSuccess.value;

  @override
  void onClose() {
    super.onClose();
  }

  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  String? validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a new password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.trim() == currentPasswordController.text.trim()) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your new password';
    }
    if (value.trim() != newPasswordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      _isLoading.value = true;
      _error.value = '';
      _isSuccess.value = false;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in.");
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Khoá auth state handler TRƯỚC khi updatePassword
      // để tránh Firebase token refresh gây ra navigate/reset userModel.
      _authController.setAuthenticating(true);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      _isSuccess.value = true;

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.snackbar(
        "Success",
        "Password changed successfully. Please sign in again.",
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      // Sign out and redirect to login after a short delay
      await Future.delayed(const Duration(seconds: 2));
      await _authController.signOutAfterPasswordChange();
    } on FirebaseAuthException catch (e) {
      // Mở khoá handler nếu lỗi xảy ra sau khi đã lock
      _authController.setAuthenticating(false);

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'The current password is incorrect.';
          break;
        case 'invalid-credential':
          errorMessage = 'The current password is incorrect.';
          break;
        case 'weak-password':
          errorMessage = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Please sign out and sign in again before changing password.';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      _error.value = errorMessage;
      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      // Mở khoá handler nếu lỗi xảy ra sau khi đã lock
      _authController.setAuthenticating(false);

      String errorMessage = e.toString();
      // Handle common Firebase errors that may not be FirebaseAuthException
      if (errorMessage.contains('wrong-password') ||
          errorMessage.contains('invalid-credential')) {
        errorMessage = 'The current password is incorrect.';
      } else if (errorMessage.contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      }
      _error.value = errorMessage;
      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
