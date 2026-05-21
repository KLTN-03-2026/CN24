import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_now_khoaluan/controllers/customer_home_controller.dart';
import 'package:ride_now_khoaluan/models/ride_request_model.dart';
import 'package:ride_now_khoaluan/theme/app_theme.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';

class CustomerHomeView extends GetView<CustomerHomeController> {
  const CustomerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          Positioned.fill(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: const LatLng(16.0544, 108.2022),
                  initialZoom: 13,
                  onTap: (tapPosition, point) {
                    FocusScope.of(context).unfocus();
                    controller.clearSearchResults();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark 
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'vn.khoaluan.ridenow.mobileapp.v1',
                  ),
                  Obx(() {
                    final points = controller.routePoints;
                    if (points.isEmpty) return const SizedBox.shrink();
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points.toList(),
                          strokeWidth: 8,
                          color: theme.primaryColor,
                        ),
                      ],
                    );
                  }),
                  Obx(() => MarkerLayer(markers: _buildMarkers())),
                ],
              ),
            ),
          ),

          // Top Search UI
          SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 10, left: 15, right: 68,
                  child: _buildSearchHeader(context),
                ),
                Positioned(
                  top: 10, right: 15,
                  child: _buildProfileAvatar(context),
                ),
              ],
            ),
          ),

          // Location Button
          Positioned(
            bottom: 30, right: 15,
            child: Obx(() {
              if (controller.currentLocation.value == null) return const SizedBox.shrink();
              return FloatingActionButton(
                heroTag: 'customer_loc_fab', // Unique tag
                backgroundColor: theme.cardColor,
                onPressed: () {
                  try {
                    controller.mapController.move(controller.currentLocation.value!, 17);
                  } catch (e) {
                    debugPrint('CustomerHomeView: error moving map: $e');
                  }
                },
                child: Icon(Icons.my_location, color: theme.primaryColor),
              );
            }),
          ),

          // Bottom Sheet
          _buildDraggableSheet(context),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: AppTheme.homeCardDecoration(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAddressField(context, controller.pickupController, 'enter_pickup'.tr, Colors.green, true),
                  const SizedBox(height: 25),
                  _buildAddressField(context, controller.destinationController, 'enter_destination'.tr, Colors.red, false),
                ],
              ),
              Positioned(
                right: 15, top: 0, bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: controller.swapLocations,
                    icon: const Icon(Icons.swap_vert, color: Colors.blue, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSearchResults(context),
      ],
    );
  }

  Widget _buildAddressField(BuildContext context, TextEditingController txtController, String hint, Color iconColor, bool isPickup) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: AppTheme.searchFieldDecoration(context),
      child: Row(
        children: [
          Icon(isPickup ? Icons.circle : Icons.location_on, color: iconColor, size: isPickup ? 18 : 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: txtController,
              decoration: AppTheme.searchInputDecoration(context, hint),
              style: const TextStyle(fontSize: 14),
              onChanged: (val) => controller.onSearchChanged(val, isPickup),
              onSubmitted: (val) => controller.searchLocation(txtController.text, isPickup), // Added logic check
            ),
          ),
          _buildFieldSuffix(context, txtController, isPickup),
        ],
      ),
    );
  }

  Widget _buildFieldSuffix(BuildContext context, TextEditingController txtController, bool isPickup) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final routing = controller.isRouting.value;
      if (!isPickup && (loading || routing)) {
        return SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor));
      }
      return IconButton(
        icon: Icon(txtController.text.isNotEmpty ? Icons.close : (isPickup ? Icons.my_location : Icons.search), size: 18),
        onPressed: () {
          if (txtController.text.isNotEmpty) {
            txtController.clear();
            controller.clearSearchResults();
            controller.routePoints.clear();
            if (isPickup) {
              controller.searchedPickupLocation.value = null;
              controller.pickupAddress.value = 'current_location'.tr;
            } else {
              controller.searchedLocation.value = null;
            }
          }
        },
      );
    });
  }

  Widget _buildSearchResults(BuildContext context) {
    return Obx(() {
      if (controller.searchResults.isEmpty ||
          controller.activeRide.value != null) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(top: 10),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: AppTheme.homeCardDecoration(context),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final result = controller.searchResults[index];
              return ListTile(
                title: Text(
                  result['display_name'] ?? '',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.location_on_outlined, size: 20),
                onTap: () => controller.selectLocation(result),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildProfileAvatar(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final user = auth.userModel;
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          image: user?.avatar != null && user!.avatar!.isNotEmpty
              ? DecorationImage(image: NetworkImage(user.avatar!), fit: BoxFit.cover)
              : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
        ),
        child: user?.avatar == null ? const Icon(Icons.person) : null,
      );
    });
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (controller.currentLocation.value != null) {
      markers.add(Marker(
        point: controller.currentLocation.value!,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
      ));
    }
    if (controller.searchedPickupLocation.value != null) {
      markers.add(Marker(
        point: controller.searchedPickupLocation.value!,
        child: const Icon(Icons.location_on, color: Colors.green, size: 35),
      ));
    }
    if (controller.searchedLocation.value != null) {
      markers.add(Marker(
        point: controller.searchedLocation.value!,
        child: const Icon(Icons.location_on, color: Colors.red, size: 35),
      ));
    }
    if (controller.driverLocation.value != null) {
      markers.add(Marker(
        point: controller.driverLocation.value!,
        width: 50, height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: const Icon(Icons.local_taxi, color: Colors.blueAccent, size: 35),
        ),
      ));
    }
    return markers;
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return Obx(() {
      final hasRoute = controller.routePoints.isNotEmpty;
      final hasActiveRide = controller.activeRide.value != null;
      if (!hasRoute && !hasActiveRide) return const SizedBox.shrink();

      return DraggableScrollableSheet(
        initialChildSize: 0.3, minChildSize: 0.1, maxChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: AppTheme.homeCardDecoration(context).copyWith(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 15),
                if (hasActiveRide) _buildRideInfo(context, controller.activeRide.value!)
                else _buildRouteInfo(context),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildRouteInfo(BuildContext context) {
    final theme = Theme.of(context);
    final distance = controller.previewDistance.value ?? 0.0;
    final duration = controller.previewDuration.value ?? 0.0;
    final price = distance * 5000;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    context,
                    'Khoảng cách',
                    '${distance.toStringAsFixed(1)} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'Thời gian',
                    '${duration.toStringAsFixed(0)} phút',
                    Icons.access_time,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'Giá tiền',
                    controller.formatVND(price),
                    Icons.payments,
                    Colors.green,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                controller.routePoints.clear();
                controller.searchedLocation.value = null;
                controller.destinationController.clear();
              },
              icon: const Icon(Icons.close, color: Colors.red, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Obx(() => SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value ? null : controller.handleBookRide,
            icon: const Icon(Icons.local_taxi, size: 24),
            label: controller.isLoading.value 
              ? const SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  'book_ride_now'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71), // Màu xanh lá như mẫu
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 100) / 3,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfo(BuildContext context, RideRequestModel _) {
    return Obx(() {
      final theme = Theme.of(context);
      final ride = controller.activeRide.value;
      if (ride == null) return const SizedBox.shrink();
      
      final isAccepted = ride.status != RideStatus.searching_driver && 
          ride.status != RideStatus.pending && 
          ride.status != RideStatus.driver_assigned;
      
      if (!isAccepted) {
        return _buildSearchingDriverUI(context, ride);
      }
      
      final driver = controller.assignedDriver.value;

      return Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                image: driver?.avatar != null 
                    ? DecorationImage(image: NetworkImage(driver!.avatar!), fit: BoxFit.cover)
                    : null,
              ),
              child: driver?.avatar == null ? const Icon(Icons.person, color: AppTheme.primaryColor) : null,
            ),
            title: Text(
              ride.driverName ?? 'finding_driver'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Status: ${ride.status.name.tr}',
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
            ),
            trailing: isAccepted 
                ? IconButton(
                    onPressed: () => controller.formatVND(0), // Placeholder for call logic
                    icon: const Icon(Icons.phone, color: Colors.green),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  )
                : const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
          if (isAccepted) ...[
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleStat(
                  Icons.star, 
                  '${driver?.rating.toStringAsFixed(1) ?? "0.0"} (${driver?.ratingCount ?? 0})', 
                  Colors.orange
                ),
                _buildSimpleStat(
                  Icons.directions_car, 
                  driver?.vehiclePlate ?? '...', 
                  Colors.blue
                ),
                _buildSimpleStat(Icons.timer, '5 min', Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: controller.isLoading.value ? null : controller.cancelActiveRide,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  foregroundColor: Colors.redAccent,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Hủy chuyến',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSearchingDriverUI(BuildContext context, RideRequestModel ride) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Green spinning progress indicator
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                strokeWidth: 4.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Centered Bold Text
        const Text(
          'Đang tìm tài xế gần bạn...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        
        // Rounded Route Addresses Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              // Pickup Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Vertical Connector Line
              Padding(
                padding: const EdgeInsets.only(left: 7.5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1.5,
                    height: 22,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
              // Destination Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.destinationAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        
        // Cancel Request Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: controller.isLoading.value ? null : controller.cancelActiveRide,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              foregroundColor: Colors.redAccent,
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.redAccent,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Hủy yêu cầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSimpleStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
