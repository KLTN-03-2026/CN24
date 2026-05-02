import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi thông báo mới
  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  // Lấy danh sách thông báo của người dùng
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      // Sắp xếp theo thời gian mới nhất lên đầu trong Dart
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Đếm số thông báo chưa đọc (realtime)
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Đánh dấu đã đánh giá
  Future<void> markAsRated(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRated': true, 'isRead': true});
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Tạo thông báo đánh giá tài xế
  Future<void> createRatingNotification({
    required String customerId,
    required String rideId,
    required String driverId,
    required String driverName,
  }) async {
    final notification = NotificationModel(
      id: 'notif_$rideId',
      userId: customerId,
      rideId: rideId,
      driverId: driverId,
      driverName: driverName,
      title: 'Đánh giá chuyến đi',
      message: 'Chuyến đi cùng tài xế $driverName đã hoàn thành. Hãy chia sẻ trải nghiệm của bạn!',
      type: NotificationType.rating,
      createdAt: DateTime.now(),
    );
    await sendNotification(notification);
  }
}
