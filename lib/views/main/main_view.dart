import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';
import 'package:ride_now_khoaluan/views/main/home/customer_home_view.dart';
import 'package:ride_now_khoaluan/views/main/home/driver_home_view.dart';
import 'package:ride_now_khoaluan/views/main/notifications/notification_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/profile_view.dart';
import 'package:ride_now_khoaluan/views/main/trips/customer_history_view.dart';
import 'package:ride_now_khoaluan/views/main/trips/driver_history_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final AuthController _authController = Get.find<AuthController>();
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    Obx(() {
      final user = _authController.userModel;
      if (user != null && user.role == UserRole.driver) {
        return const DriverHomeScreen();
      }
      return const CustomerHomeView();
    }),
    Obx(() {
      final user = _authController.userModel;
      if (user != null && user.role == UserRole.driver) {
        return const DriverTripHistoryScreen();
      }
      return const CustomerTripHistoryScreen();
    }),
    const NotificationView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
