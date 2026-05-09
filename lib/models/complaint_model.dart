import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String tripId;
  final String userId;
  final String userRole; // "customer" or "driver"
  final String? targetUserId;
  final String reason;
  final String description;
  final String status; // "pending", "in_progress", "resolved", "rejected"
  final String? adminNotes;
  final List<String>? images;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userRole,
    this.targetUserId,
    required this.reason,
    required this.description,
    this.status = 'pending',
    this.adminNotes,
    this.images,
    required this.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      tripId: map['tripId'] ?? '',
      userId: map['userId'] ?? '',
      userRole: map['userRole'] ?? '',
      targetUserId: map['targetUserId'],
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'userRole': userRole,
      'targetUserId': targetUserId,
      'reason': reason,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
