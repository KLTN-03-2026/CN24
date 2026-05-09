import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import 'widgets/rating_dialog.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final NotificationService _notificationService = NotificationService();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'notifications'.tr,
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final userId = _authController.userModel?.id;
        if (userId == null) {
          return const Center(child: Text('Vui lòng đăng nhập để xem thông báo'));
        }

        return StreamBuilder<List<NotificationModel>>(
          stream: _notificationService.watchNotifications(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có thông báo nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isRating = notif.type == NotificationType.rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.isRead 
            ? theme.cardColor 
            : (isDark ? theme.primaryColor.withOpacity(0.1) : const Color(0xFFEDF4FE)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notif.isRead) {
              _notificationService.markAsRead(notif.id);
            }
            if (isRating && !notif.isRated) {
              _showRatingDialog(notif);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRating 
                            ? (isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50) 
                            : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRating ? Icons.star : Icons.info_outline,
                        color: isRating ? Colors.orange : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(notif.createdAt),
                            style: TextStyle(
                              fontSize: 11, 
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.primaryColor, 
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notif.message,
                  style: TextStyle(
                    fontSize: 14, 
                    color: theme.colorScheme.onSurfaceVariant, 
                    height: 1.4,
                  ),
                ),
                if (isRating) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: notif.isRated ? null : () => _showRatingDialog(notif),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: notif.isRated ? Colors.grey.shade200 : const Color(0xFF223285),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        notif.isRated ? 'Đã đánh giá' : 'Đánh giá ngay',
                        style: TextStyle(
                          color: notif.isRated ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(NotificationModel notif) {
    if (notif.driverId == null) return;
    Get.dialog(
      RatingDialog(
        rideId: notif.rideId,
        driverId: notif.driverId!,
        driverName: notif.driverName ?? 'Tài xế',
        notificationId: notif.id,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
