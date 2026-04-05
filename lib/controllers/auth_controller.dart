import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isInitialized = false.obs;

  // Flag ngăn auth state change navigate khi đang xác thực (login/register)
  bool _isAuthenticating = false;

  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value != null;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_authService.authStateChanges);
    ever<User?>(_user, _handleAuthStateChange);
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (!_isInitialized.value) _isInitialized.value = true;

    // Đang xác thực (login/register) → không làm gì, chờ tác vụ hoàn thành
    if (_isAuthenticating) return;

    if (user == null) {
      _userModel.value = null;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != AppRoutes.login) {
          Get.offAllNamed(AppRoutes.login);
        }
      });
      return;
    }

    try {
      _isLoading.value = true;

      if (_userModel.value == null || _userModel.value!.id != user.uid) {
        final model = await _authService.fetchUserModel(user.uid);
        if (model == null) {
          _error.value =
              'Không tìm thấy user trong Firestore (users/${user.uid}).';
        }
        _userModel.value = model;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Chỉ redirect sang Main nếu đang ở Splash, Login hoặc Register
      final currentRoute = Get.currentRoute;
      if (currentRoute == AppRoutes.login || 
          currentRoute == AppRoutes.register || 
          currentRoute == AppRoutes.splash ||
          currentRoute == AppRoutes.onboarding) {
        Get.offAllNamed(AppRoutes.main);
      }
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      _isAuthenticating = true; // Lock auth state handler

      final userModel = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _userModel.value = userModel;
      
      // In ra Role của người dùng vừa đăng nhập
      debugPrint('====================================');
      debugPrint('[LOGIN SUCCESS] Role của bạn là: ${userModel.role.name.toUpperCase()}');
      debugPrint('====================================');
      
      Get.snackbar('Thành công', 'Đăng nhập thành công với quyền ${userModel.role.name}!');
      
      // Navigate to main screen
      await Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed To Login: ${e.toString()}');
    } finally {
      _isAuthenticating = false;
      _isLoading.value = false;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      _isAuthenticating = true; // Lock auth state handler

      UserRole userRole = UserRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => UserRole.customer,
      );

      final userModel = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        role: userRole,
      );

      if (userModel == null) {
        throw Exception('Registration failed: User model is null.');
      }

      // Set userModel before unlocking to avoid race condition
      _userModel.value = userModel;

      Get.snackbar('Thành công', 'Đăng ký thành công!');

      // Navigate to main screen
      await Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      _error.value = e.toString();
      debugPrint('[Register Error] $e');
      Get.snackbar('Lỗi', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isAuthenticating = false; // Luôn mở khóa handler
      _isLoading.value = false; // Luôn tắt loading
    }
  }

  Future<void> updateUserStatus({bool? isOnline, bool? isAvailable}) async {
    if (_userModel.value == null) return;
    
    final updatedModel = _userModel.value!.copyWith(
      isOnline: isOnline ?? _userModel.value!.isOnline,
      isAvailable: isAvailable ?? _userModel.value!.isAvailable,
    );
    
    await _authService.updateUserModel(updatedModel);
    _userModel.value = updatedModel;
  }

  Future<void> completeRide(double fare) async {
    if (_userModel.value == null) return;
    
    final updatedModel = _userModel.value!.copyWith(
      earnings: _userModel.value!.earnings + fare,
      totalTrips: _userModel.value!.totalTrips + 1,
    );
    
    await _authService.updateUserModel(updatedModel);
    _userModel.value = updatedModel;
    debugPrint('[AuthController] Ride completed. New earnings: ${updatedModel.earnings}');
  }

  Future<void> updateUserPhone(String phone) async {
    if (_userModel.value == null) return;
    
    _isLoading.value = true;
    try {
      final updatedModel = _userModel.value!.copyWith(
        phone: phone,
      );
      
      await _authService.updateUserModel(updatedModel);
      _userModel.value = updatedModel;
      Get.snackbar('Thành công', 'Đã cập nhật số điện thoại.');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật số điện thoại: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void logOut() async {
    await _authService.logOut();
    _userModel.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
