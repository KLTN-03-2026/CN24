import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ride_request_model.dart';
import '../models/user_model.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Công thức Haversine để tính khoảng cách giữa 2 điểm (km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Tìm driver gần nhất (Sẽ dùng MatchingService thay thế cho luồng phức tạp hơn)
  // Giữ lại createRideRequest nếu cần cho các luồng đơn giản, nhưng CustomerHomeView đang dùng MatchingService.
  // Xóa để tránh nhầm lẫn.

  // Tạo request trực tiếp từ model
  Future<String> createRideRequest(RideRequestModel request) async {
    try {
      final docRef = _firestore.collection('ride_requests').doc();
      final newRequest = request.copyWith(id: docRef.id);
      await docRef.set(newRequest.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('[RideService] createRideRequest Error: $e');
      rethrow;
    }
  }

  // Cập nhật trạng thái chuyến xe
  Future<void> updateRideStatus(String requestId, RideStatus newStatus) async {
    try {
      await _firestore.collection('ride_requests').doc(requestId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      debugPrint('[RideService] updateRideStatus Error: $e');
      rethrow;
    }
  }

  // Hủy chuyến xe
  Future<void> cancelRideRequest(String requestId) async {
    try {
      await updateRideStatus(requestId, RideStatus.cancelled);
    } catch (e) {
      debugPrint('[RideService] cancelRideRequest Error: $e');
      rethrow;
    }
  }

  // Hoàn thành chuyến xe và cập nhật trip đã tồn tại
  Future<void> completeRide(String requestId, Map<String, dynamic> updateData) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      // 1. Cập nhật trạng thái ride request
      batch.update(_firestore.collection('ride_requests').doc(requestId), {
        'status': RideStatus.completed.name,
      });

      // 2. Cập nhật trip đã tồn tại (ongoing → completed)
      batch.update(_firestore.collection('trips').doc(requestId), updateData);

      await batch.commit();
    } catch (e) {
      debugPrint('[RideService] completeRide Error: $e');
      rethrow;
    }
  }
}
