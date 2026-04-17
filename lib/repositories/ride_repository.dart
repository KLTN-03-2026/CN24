import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ride_request_model.dart';
import '../models/trip_model.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo ride request mới
  Future<void> createRideRequest(RideRequestModel request) async {
    await _firestore
        .collection('ride_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  // Cập nhật trạng thái ride request
  Future<void> updateRideStatus(String requestId, RideStatus status) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'status': status.name,
    });
  }

  // Chấp nhận chuyến xe (cập nhật status + thông tin tài xế) - Sử dụng Transaction để an toàn
  Future<void> acceptRide(
    String requestId,
    String driverName,
    String driverPhone,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final DocumentReference rideRef = _firestore
            .collection('ride_requests')
            .doc(requestId);
        final DocumentSnapshot snapshot = await transaction.get(rideRef);

        if (!snapshot.exists) {
          throw Exception('Chuyến xe không tồn tại.');
        }

        final String currentStatus = snapshot.get('status');
        // Chỉ cho phép "Chấp nhận" nếu dang ở trạng thái driver_assigned hoặc searching_driver
        if (currentStatus != RideStatus.driver_assigned.name &&
            currentStatus != RideStatus.searching_driver.name) {
          throw Exception(
            'Xin lỗi, chuyến xe này đã có người khác nhận hoặc đã bị hủy.',
          );
        }

        transaction.update(rideRef, {
          'status': RideStatus.accepted.name,
          'driverName': driverName,
          'driverPhone': driverPhone,
        });
      });
    } catch (e) {
      debugPrint('[RideRepository] Error in acceptRide Transaction: $e');
      rethrow;
    }
  }

  // Gán tài xế cho request
  Future<void> assignDriver(
    String requestId,
    String driverId,
    double distance,
    String? driverPhone,
    String? driverName,
  ) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'driverId': driverId,
      'distanceInKm': distance,
      'driverPhone': driverPhone,
      'driverName': driverName,
      'status': RideStatus.driver_assigned.name,
    });
  }

  // Lấy stream của một request cụ thể
  Stream<RideRequestModel> watchRideRequest(String requestId) {
    return _firestore
        .collection('ride_requests')
        .doc(requestId)
        .snapshots()
        .map(
          (doc) => RideRequestModel.fromMap(
            doc.data() as Map<String, dynamic>? ?? {},
          ),
        );
  }

  // Stream cho driver lắng nghe request mới
  Stream<List<RideRequestModel>> watchIncomingRequests(String driverId) {
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: RideStatus.driver_assigned.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RideRequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // Stream chuyến xe đang thực hiện (chỉ trong vòng 24h gần nhất)
  Stream<RideRequestModel?> watchActiveRide(String driverId) {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where(
          'status',
          whereIn: [RideStatus.accepted.name, RideStatus.on_the_way.name],
        )
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return RideRequestModel.fromMap(
              snapshot.docs.first.data() as Map<String, dynamic>,
            );
          }
          return null;
        });
  }

  // Tạo trip ongoing ngay khi driver accept chuyến
  Future<void> createOngoingTrip(TripModel trip) async {
    await _firestore.collection('trips').doc(trip.id).set(trip.toMap());
  }

  // Hoàn thành chuyến xe, cập nhật trip đã tồn tại
  Future<void> completeRide(
    String requestId,
    Map<String, dynamic> updateData,
  ) async {
    final WriteBatch batch = _firestore.batch();

    // 1. Cập nhật trạng thái ride request
    batch.update(_firestore.collection('ride_requests').doc(requestId), {
      'status': RideStatus.completed.name,
    });

    // 2. Cập nhật trip đã tồn tại (ongoing → completed)
    batch.update(_firestore.collection('trips').doc(requestId), updateData);

    await batch.commit();
  }

  // Lấy danh sách chuyến xe (history) của customer với filter
  Stream<List<TripModel>> watchTripsForCustomer(
    String userId, {
    String? status,
    String? searchQuery,
  }) {
    return _firestore
        .collection('trips')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var trips = snapshot.docs
              .map(
                (doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Sắp xếp: ongoing lên đầu, sau đó theo thời gian mới nhất
          trips.sort((a, b) {
            // Ongoing luôn lên đầu
            if (a.status == 'ongoing' && b.status != 'ongoing') return -1;
            if (a.status != 'ongoing' && b.status == 'ongoing') return 1;
            // Cùng loại thì sort theo createdAt giảm dần
            return b.createdAt.compareTo(a.createdAt);
          });

          // Filter theo status trong Dart
          if (status != null && status != 'Tất cả') {
            trips = trips
                .where((t) => t.status.toLowerCase() == status.toLowerCase())
                .toList();
          }

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final searchLower = searchQuery.toLowerCase();
            trips = trips
                .where(
                  (t) =>
                      t.id.toLowerCase().contains(searchLower) ||
                      t.pickupAddress.toLowerCase().contains(searchLower) ||
                      t.destinationAddress.toLowerCase().contains(searchLower),
                )
                .toList();
          }

          return trips;
        });
  }

  // Lấy danh sách chuyến xe (history) của driver với filter
  Stream<List<TripModel>> watchTripsForDriver(String userId, {String? status}) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var trips = snapshot.docs
              .map(
                (doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Sắp xếp: ongoing lên đầu, sau đó theo thời gian mới nhất
          trips.sort((a, b) {
            if (a.status == 'ongoing' && b.status != 'ongoing') return -1;
            if (a.status != 'ongoing' && b.status == 'ongoing') return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          if (status != null && status != 'Tất cả') {
            trips = trips
                .where((t) => t.status.toLowerCase() == status.toLowerCase())
                .toList();
          }

          return trips;
        });
  }

  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .get();

    final allTrips = snapshot.docs.map((doc) => doc.data()).toList();
    final completedTrips = allTrips
        .where((t) => t['status'] == 'completed')
        .toList();

    double totalEarnings = 0;
    for (var trip in completedTrips) {
      totalEarnings += (trip['fare'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalTrips': completedTrips.length,
      'totalEarnings': totalEarnings,
      'completedTrips': completedTrips.length,
    };
  }
}
