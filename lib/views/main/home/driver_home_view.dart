import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/ride_request_model.dart';
import '../../../models/trip_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../../services/location_service.dart';
import '../../driver/driver_navigation_screen.dart';
import '../../driver/widgets/ride_request_card.dart';
import '../profiles/profile_view.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  final AuthController _authController = Get.find<AuthController>();
  final LocationService _locationService = LocationService();
  final RideRepository _rideRepository = RideRepository();
  StreamSubscription? _requestSubscription;
  StreamSubscription? _activeRideSubscription;
  RideRequestModel? _currentRequest;
  RideRequestModel? _activeRide;

  @override
  void initState() {
    super.initState();
    
    // Lắng nghe sự thay đổi của userModel để khởi chạy các dịch vụ tương ứng
    ever(_authController.userModelRx, (user) {
      if (user != null) {
        _startWatchingActiveRide(user.id);
        if (user.isOnline == true) {
          _startDriverServices();
        }
      }
    });

    // Chạy thử lần đầu nếu user đã có sẵn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authController.userModel;
      if (user != null) {
        _startWatchingActiveRide(user.id);
        if (user.isOnline == true) {
          _startDriverServices();
        }
      }
    });
  }

  @override
  void dispose() {
    _stopDriverServices();
    super.dispose();
  }

  void _startDriverServices() {
    final driverId = _authController.userModel?.id;
    print('DEBUG: [DriverHomeScreen] _startDriverServices: driverId=$driverId');
    if (driverId == null) return;

    // 1. Cập nhật vị trí realtime
    _locationService.startDriverLocationUpdates(driverId);

    // 2. Lắng nghe request mới (chỉ những request được assign cho driver này)
    _requestSubscription?.cancel();
    _requestSubscription = _rideRepository
        .watchIncomingRequests(driverId)
        .listen((requests) {
          print('DEBUG: [DriverHomeScreen] Nhận được ${requests.length} requests mới');
          if (requests.isNotEmpty) {
            print('DEBUG: [DriverHomeScreen] Request đầu tiên: ${requests.first.id}, status: ${requests.first.status}');
            if (mounted) {
              setState(() => _currentRequest = requests.first);
            }
          } else {
            if (mounted) {
              setState(() => _currentRequest = null);
            }
          }
        });

    // 3. Cũng lắng nghe active ride (để recover nếu app restart giữa chuyến)
    _startWatchingActiveRide(driverId);
  }

  /// Bắt đầu theo dõi chuyến đang thực hiện.
  /// Gọi ngay sau khi accept hoặc khi khởi động lại app giữa chuyến.
  void _startWatchingActiveRide(String driverId) {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = _rideRepository.watchActiveRide(driverId).listen((
      ride,
    ) {
      if (mounted) {
        setState(() => _activeRide = ride);
      }
    });
  }

  void _stopDriverServices() {
    _locationService.stopDriverLocationUpdates();
    _requestSubscription?.cancel();
    _activeRideSubscription?.cancel();
  }

  Future<void> _toggleOnlineStatus(bool val) async {
    final driverId = _authController.userModel?.id;
    if (driverId == null) return;

    try {
      // Cập nhật lên Firestore thông qua AuthController
      await _authController.updateUserStatus(isOnline: val, isAvailable: val);

      if (val) {
        _startDriverServices();
      } else {
        // Khi offline thì dừng cập nhật vị trí và lắng nghe request mới, 
        // NHƯNG vẫn giữ _activeRideSubscription để theo dõi chuyến đang đi.
        _locationService.stopDriverLocationUpdates();
        _requestSubscription?.cancel();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    print('DEBUG: [DriverHomeScreen] Build: _activeRide=${_activeRide?.id}, _currentRequest=${_currentRequest?.id}');
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Ride Now',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Get.to(() => const ProfileView()),
              child: CircleAvatar(
                backgroundColor: theme.primaryColor,
                radius: 18,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Toggle Card
            Obx(() {
              final isOnline = _authController.userModel?.isOnline ?? false;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: _toggleOnlineStatus,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Map Placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? theme.primaryColor.withOpacity(0.05) : const Color(0xFFEDF4FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map will appear here',
                    style: TextStyle(
                      color: Colors.blue.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Obx(() {
              final user = _authController.userModel;
              return Row(
                children: [
                  _buildStatCard(
                    'TRIPS',
                    '${user?.totalTrips ?? 0}',
                    Colors.indigo,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'RATING',
                    '${user?.rating.toStringAsFixed(1) ?? "0.0"} ⭐',
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'EARNINGS',
                    _formatVND(user?.earnings ?? 0),
                    Colors.green,
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Active Ride or New Request Card
            if (_activeRide != null)
              RideRequestCard(
                request: _activeRide!,
                isActiveRide: true,
                onNavigate: () {
                  Get.to(
                    () => DriverNavigationScreen(activeRide: _activeRide!),
                  );
                },
                onComplete: () async {
                  try {
                    final rideId = _activeRide!.id;
                    final fare = _activeRide!.fare ?? 0;

                    // Chỉ cập nhật trip đã tồn tại (ongoing → completed)
                    await _rideRepository.completeRide(rideId, {
                      'status': 'completed',
                      'completedAt': Timestamp.fromDate(DateTime.now()),
                      'fare': fare,
                    });

                    // Cộng tiền và tăng chuyến cho tài xế
                    await _authController.completeRide(fare);

                    if (mounted) setState(() => _activeRide = null);
                    // Khi xong chuyến, gán lại isAvailable = true
                    await _authController.updateUserStatus(isAvailable: true);

                    Get.snackbar(
                      'Hoàn thành',
                      'Chuyến đi kết thúc. Bạn nhận được ${_formatVND(fare)}!',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    debugPrint('[DriverHomeScreen] completeRide error: $e');
                    Get.snackbar(
                      'Lỗi',
                      'Không thể hoàn thành chuyến: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 5),
                    );
                  }
                },
              )
            else if (_currentRequest != null)
              RideRequestCard(
                request: _currentRequest!,
                onAccept: () async {
                  final accepted = _currentRequest!;
                  Get.showOverlay(
                    asyncFunction: () async {
                      try {
                        final driver = _authController.userModel;
                        await _rideRepository.acceptRide(
                          accepted.id,
                          driver?.name ?? 'Tài xế',
                          driver?.phone ?? '',
                        );

                        // Tạo trip ongoing ngay khi accept
                        final trip = TripModel(
                          id: accepted.id,
                          customerId: accepted.customerId,
                          customerName: accepted.customerName,
                          driverId: driver?.id ?? '',
                          driverName: driver?.name ?? 'Tài xế',
                          pickupAddress: accepted.pickupAddress,
                          pickupLatitude: accepted.pickupLatitude,
                          pickupLongitude: accepted.pickupLongitude,
                          destinationAddress: accepted.destinationAddress,
                          destinationLatitude: accepted.destinationLatitude,
                          destinationLongitude: accepted.destinationLongitude,
                          fare: accepted.fare ?? 0,
                          distance: accepted.distanceInKm ?? 0,
                          status: 'ongoing',
                          paymentMethod: accepted.paymentMethod,
                          createdAt: DateTime.now(),
                        );
                        await _rideRepository.createOngoingTrip(trip);

                        if (mounted) setState(() => _currentRequest = null);
                        // Chuyển status driver sang bận
                        await _authController.updateUserStatus(
                          isAvailable: false,
                        );
                        Get.snackbar(
                          "Thành công",
                          "Bạn đã nhận cuốc xe thành công! Hãy bắt đầu di chuyển.",
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          duration: const Duration(seconds: 4),
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Thất bại",
                          e.toString().replaceFirst('Exception: ', ''),
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 4),
                        );
                        if (mounted) setState(() => _currentRequest = null);
                      }
                    },
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  // Bắt đầu theo dõi chuyến ngay sau khi accept
                  final driverId = _authController.userModel?.id;
                  if (driverId != null) _startWatchingActiveRide(driverId);
                },
                onDecline: () async {
                  await _rideRepository.updateRideStatus(
                    _currentRequest!.id,
                    RideStatus.rejected,
                  );
                  if (mounted) setState(() => _currentRequest = null);
                },
              ),
            const SizedBox(height: 24),

            // Bottom Actions
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: () {},
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFF223285),
            //       elevation: 0,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     ),
            //     child: const Text(
            //       'Start Driving',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontWeight: FontWeight.w800,
            //         fontSize: 15,
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton(
            //     onPressed: () {},
            //     style: OutlinedButton.styleFrom(
            //       side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     ),
            //     child: const Text(
            //       'Go Offline',
            //       style: TextStyle(
            //         color: Color(0xFF4B5563),
            //         fontWeight: FontWeight.w800,
            //         fontSize: 15,
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatVND(double amount) {
    // Định dạng số: 10000 -> 10.000
    final String str = amount.round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} VND';
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
