import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/trip_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../widgets/trip_history_card.dart';
import 'trip_detail_view.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  final _rideRepository = RideRepository();
  final _authController = Get.find<AuthController>();
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final userId = _authController.userModel?.id ?? '';
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Lịch sử thu thập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<TripModel>>(
        stream: _rideRepository.watchTripsForDriver(
          userId,
          // status: _selectedFilter, // Fetch all for stats
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allTrips = snapshot.data ?? [];

          final completedTrips = allTrips
              .where((t) => t.status.toLowerCase() == 'completed')
              .toList();
          final totalEarnings = completedTrips.fold<double>(
            0,
            (sum, t) => sum + t.fare,
          );
          final tripCount = completedTrips.length;

          // Filter list for display
          final filteredTrips = _selectedFilter == 'Tất cả'
              ? allTrips
              : allTrips
                    .where(
                      (t) =>
                          t.status.toLowerCase() ==
                          _selectedFilter.toLowerCase(),
                    )
                    .toList();

          return Column(
            children: [
              // Stats Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard(
                      'Số chuyến',
                      '$tripCount',
                      Icons.directions_car,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Thu nhập',
                      currencyFormat.format(totalEarnings),
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              // Filter Row
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) =>
                            setState(() => _selectedFilter = filter),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF223285).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF223285)
                              : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF223285)
                                : Colors.grey[200]!,
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: filteredTrips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có lịch sử chuyến đi',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = filteredTrips[index];
                          return TripHistoryCard(
                            trip: trip,
                            onTap: () =>
                                Get.to(() => TripDetailScreen(trip: trip)),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
