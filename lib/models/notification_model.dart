import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { rating, info, promotion }

class NotificationModel {
  final String id;
  final String userId;
  final String rideId;
  final String? driverId;
  final String? driverName;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRated;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.rideId,
    this.driverId,
    this.driverName,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.isRated = false,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'rideId': rideId,
      'driverId': driverId,
      'driverName': driverName,
      'title': title,
      'message': message,
      'type': type.name,
      'isRated': isRated,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      rideId: map['rideId'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      isRated: map['isRated'] ?? false,
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
