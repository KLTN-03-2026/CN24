import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/trip_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../widgets/trip_history_card.dart';
import 'trip_detail_view.dart';

class CustomerTripHistoryScreen extends StatefulWidget {
  const CustomerTripHistoryScreen({super.key});

  @override
  State<CustomerTripHistoryScreen> createState() =>
      _CustomerTripHistoryScreenState();
}

class _CustomerTripHistoryScreenState extends State<CustomerTripHistoryScreen> {
  final _rideRepository = RideRepository();
  final _authController = Get.find<AuthController>();
  String _selectedFilter = 'Tất cả';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _filters = ['Tất cả', 'Completed', 'Cancelled', 'Ongoing'];

  @override
  Widget build(BuildContext context) {
    final userId = _authController.userModel?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Lịch sử chuyến đi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã chuyến, địa điểm...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SizedBox(
                  height: 35,
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
                          selectedColor: const Color(
                            0xFF223285,
                          ).withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF223285)
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
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
              ],
            ),
          ),

          // History List
          Expanded(
            child: StreamBuilder<List<TripModel>>(
              stream: _rideRepository.watchTripsForCustomer(
                userId,
                status: _selectedFilter,
                searchQuery: _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return TripHistoryCard(
                        trip: trip,
                        onTap: () => Get.to(() => TripDetailScreen(trip: trip)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Chưa có chuyến đi nào',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'Tất cả')
            TextButton(
              onPressed: () => setState(() {
                _selectedFilter = 'Tất cả';
                _searchQuery = '';
                _searchController.clear();
              }),
              child: const Text('Xóa bộ lọc'),
            ),
        ],
      ),
    );
  }
}
