import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/controllers/driver_home_controller.dart';
import 'package:ride_now_khoaluan/models/ride_request_model.dart';
import 'package:ride_now_khoaluan/views/driver/driver_navigation_screen.dart';
import 'package:ride_now_khoaluan/views/driver/widgets/ride_request_card.dart';
import 'package:ride_now_khoaluan/views/AI/chat_bot_view.dart';
import 'package:ride_now_khoaluan/views/main/profiles/profile_view.dart';
import 'package:ride_now_khoaluan/theme/app_theme.dart';

class DriverHomeScreen extends GetView<DriverHomeController> {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
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
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Online Status Switch Card
                Obx(() {
                  final isOnline = controller.isOnline.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isOnline,
                          onChanged: (val) => controller.toggleOnlineStatus(),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.green,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 2. Map Placeholder Card
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 54,
                        color: theme.primaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Map will appear here',
                        style: TextStyle(
                          color: theme.primaryColor.withOpacity(0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Stats row (Trips, Rating, Earnings)
                Obx(() {
                  final user = authController.userModel;
                  final totalTrips = user?.totalTrips ?? 0;
                  final rating = user?.rating ?? 0.0;
                  final earnings = user?.earnings ?? 0.0;

                  final currencyFormatter = NumberFormat('#,###', 'vi_VN');
                  final formattedEarnings = '${currencyFormatter.format(earnings)} VND';

                  return Row(
                    children: [
                      // Trips Stat Card
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'TRIPS',
                          '$totalTrips',
                          textColor: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Rating Stat Card
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'RATING',
                          rating.toStringAsFixed(1),
                          textColor: Colors.orange,
                          suffixIcon: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Earnings Stat Card
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'EARNINGS',
                          formattedEarnings,
                          textColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),

                // 4. Active Ride Card or Incoming Request Card
                Obx(() {
                  final activeRide = controller.activeRide.value;
                  final currentRequest = controller.currentRequest.value;

                  if (activeRide != null) {
                    return _buildActiveRideCard(context, activeRide);
                  } else if (currentRequest != null) {
                    return RideRequestCard(
                      request: currentRequest,
                      onAccept: () => controller.acceptRide(currentRequest.id),
                      onDecline: () => controller.declineRide(currentRequest.id),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value, {
    required Color textColor,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (suffixIcon != null) ...[
                const SizedBox(width: 4),
                suffixIcon,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideCard(BuildContext context, RideRequestModel ride) {
    final theme = Theme.of(context);
    
    // Format fare
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final formattedFare = '${currencyFormatter.format(ride.fare ?? 0.0)} VND';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Ride',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  formattedFare,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.primaryColor.withOpacity(0.12),
                      child: Icon(Icons.person, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.customerName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ride.distanceInKm != null
                              ? '${ride.distanceInKm!.toStringAsFixed(1)} km away'
                              : 'Location unknown',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stepper / Journey Route Timeline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 45,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICKUP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.pickupAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DROP-OFF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.destinationAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons layout
                Column(
                  children: [
                    Row(
                      children: [
                        // Gọi khách hàng (Call Customer)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (ride.customerPhone != null && ride.customerPhone!.isNotEmpty) {
                                  launchUrlString('tel:${ride.customerPhone}');
                                } else {
                                  Get.snackbar(
                                    'Thông báo', 
                                    'Khách hàng không cung cấp số điện thoại.',
                                    backgroundColor: Colors.orangeAccent,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                              icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                              label: const Text(
                                'Gọi khách hàng',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dẫn đường (Navigate to Customer)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => Get.to(() => DriverNavigationScreen(activeRide: ride)),
                              icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                              label: const Text(
                                'Dẫn đường',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hoàn thành chuyến đi (Complete Ride)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => controller.completeActiveRide(),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                        label: const Text(
                          'Hoàn thành chuyến đi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 2,
                          shadowColor: Colors.green.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
