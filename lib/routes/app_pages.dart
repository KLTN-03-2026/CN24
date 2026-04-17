import 'package:get/get.dart';
import 'package:ride_now_khoaluan/routes/app_routes.dart';
import 'package:ride_now_khoaluan/views/OnboardingScreen.dart';
import 'package:ride_now_khoaluan/views/SmartRideScreen.dart';
import 'package:ride_now_khoaluan/views/auth/login_view.dart';
import 'package:ride_now_khoaluan/views/auth/register_view.dart';
import 'package:ride_now_khoaluan/views/change_password_view.dart';
import 'package:ride_now_khoaluan/views/main/main_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SmartRideScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => OnboardingScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(name: AppRoutes.main, page: () => const MainView()),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),
  ];
}
