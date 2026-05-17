import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';
import 'package:ride_now_khoaluan/services/notification_service.dart';
import 'package:ride_now_khoaluan/views/AI/chat_bot_view.dart';
import 'package:ride_now_khoaluan/views/main/home/customer_home_view.dart';
import 'package:ride_now_khoaluan/views/main/home/driver_home_view.dart';
import 'package:ride_now_khoaluan/views/main/notifications/notification_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/profile_view.dart';
import 'package:ride_now_khoaluan/views/main/trips/customer_history_view.dart';
import 'package:ride_now_khoaluan/views/main/trips/driver_history_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/settings_view.dart';


class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = NotificationService();
  int _currentIndex = 0;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;

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
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _startWatchingUnread();

    // Lắng nghe khi user thay đổi (login/logout)
    ever(_authController.userModelRx, (_) => _startWatchingUnread());
  }

  void _startWatchingUnread() {
    _unreadSubscription?.cancel();
    final userId = _authController.userModel?.id;
    if (userId == null) return;

    _unreadSubscription = _notificationService.watchUnreadCount(userId).listen((count) {
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatbot_fab', // Added unique tag
        onPressed: () => Get.to(() => const ChatBotView()),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
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
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'home'.tr),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: 'trips'.tr,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications),
            ),
            label: 'notifications'.tr,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'profile'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: 'settings'.tr),
        ],
      ),
    );
  }
}
