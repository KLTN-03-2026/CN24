import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';

class TripHistoryCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const TripHistoryCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final fareFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Status & Date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(trip.completedAt ?? trip.createdAt),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(trip.status),
                ],
              ),
            ),
            
            // Route Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.circle, color: Colors.blue, size: 12),
                      Container(width: 2, height: 25, color: Colors.grey[200]),
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.pickupAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          trip.destinationAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            
            // Footer with Price & Distance
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildInfoChip(context, Icons.route, '${trip.distance.toStringAsFixed(1)} km'),
                      const SizedBox(width: 8),
                      _buildInfoChip(context, Icons.payments_outlined, trip.paymentMethod),
                      if (trip.rating != null) ...[
                        const SizedBox(width: 8),
                        _buildInfoChip(context, Icons.star, '${trip.rating}', iconColor: Colors.amber),
                      ],
                    ],
                  ),
                  Text(
                    fareFormat.format(trip.fare),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = const Color(0xFFC62828);
        bgColor = const Color(0xFFFFEBEE);
        text = 'Đã hủy';
        break;
      case 'ongoing':
        color = const Color(0xFF1565C0);
        bgColor = const Color(0xFFE3F2FD);
        text = 'Đang chạy';
        break;
      default:
        color = Colors.grey[700]!;
        bgColor = Colors.grey[100]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, {Color? iconColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
