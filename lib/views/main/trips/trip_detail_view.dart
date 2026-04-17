import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trip_model.dart';

class TripDetailScreen extends StatelessWidget {
  final TripModel trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chi tiết chuyến đi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _getStatusColor(trip.status).withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Icon(
                    trip.status == 'completed'
                        ? Icons.check_circle
                        : trip.status == 'ongoing'
                            ? Icons.directions_car
                            : Icons.error,
                    size: 64,
                    color: _getStatusColor(trip.status),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trip.status == 'completed'
                        ? 'Chuyến đi hoàn thành'
                        : trip.status == 'ongoing'
                            ? 'Đang trong chuyến đi'
                            : trip.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(trip.status),
                    ),
                  ),
                  Text(
                    trip.completedAt != null
                        ? dateFormat.format(trip.completedAt!)
                        : dateFormat.format(trip.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lộ trình'),
                  const SizedBox(height: 16),
                  _buildRouteItem(
                    Icons.circle,
                    Colors.blue,
                    'Điểm đón',
                    trip.pickupAddress,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRouteItem(
                    Icons.location_on,
                    Colors.red,
                    'Điểm đến',
                    trip.destinationAddress,
                  ),

                  const Divider(height: 48),

                  _buildSectionTitle('Thông tin chuyến đi'),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Mã chuyến đi',
                    trip.id.substring(0, 8).toUpperCase(),
                  ),
                  _buildDetailRow('Tài xế', trip.driverName),
                  _buildDetailRow('Khách hàng', trip.customerName),
                  _buildDetailRow(
                    'Quãng đường',
                    '${trip.distance.toStringAsFixed(1)} km',
                  ),
                  _buildDetailRow('Thanh toán', trip.paymentMethod),

                  const Divider(height: 48),

                  _buildSectionTitle('Chi phí'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(trip.fare),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF223285),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRouteItem(
    IconData icon,
    Color color,
    String label,
    String address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
