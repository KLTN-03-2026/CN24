import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/driver_home_controller.dart';
import 'package:ride_now_khoaluan/models/ride_request_model.dart';
import 'package:ride_now_khoaluan/views/driver/driver_navigation_screen.dart';
import 'package:ride_now_khoaluan/views/driver/widgets/ride_request_card.dart';
import 'package:ride_now_khoaluan/theme/app_theme.dart';

class DriverHomeScreen extends GetView<DriverHomeController> {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('driver_home'.tr),
        actions: [
          Obx(() => Switch(
            value: controller.isOnline.value,
            onChanged: (val) => controller.toggleOnlineStatus(),
            activeColor: Colors.green,
          )),
        ],
      ),
      body: Stack(
        children: [
          _buildMainStatus(context),
          Obx(() {
            final request = controller.currentRequest.value;
            if (request == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 20, left: 15, right: 15,
              child: RideRequestCard(
                request: request,
                onAccept: () => controller.acceptRide(request.id),
                onDecline: () => controller.declineRide(request.id),
              ),
            );
          }),
          Obx(() {
            final active = controller.activeRide.value;
            if (active == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 20, left: 15, right: 15,
              child: _buildActiveRideCard(context, active),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainStatus(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Icon(
            controller.isOnline.value ? Icons.check_circle : Icons.offline_bolt,
            size: 100,
            color: controller.isOnline.value ? Colors.green : Colors.grey,
          )),
          const SizedBox(height: 20),
          Obx(() => Text(
            controller.isOnline.value ? 'You are Online' : 'You are Offline',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          )),
          const SizedBox(height: 10),
          const Text('Wait for incoming requests...'),
        ],
      ),
    );
  }

  Widget _buildActiveRideCard(BuildContext context, RideRequestModel ride) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Active Journey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text('From: ${ride.pickupAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('To: ${ride.destinationAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => Get.to(() => DriverNavigationScreen(activeRide: ride)),
              child: const Text('Continue Navigation'),
            ),
          ],
        ),
      ),
    );
  }
}
