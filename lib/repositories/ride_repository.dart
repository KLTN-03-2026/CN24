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

  // Lấy thông tin một request cụ thể
  Future<RideRequestModel?> getRideRequest(String requestId) async {
    final doc =
        await _firestore.collection('ride_requests').doc(requestId).get();
    if (!doc.exists) return null;
    return RideRequestModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Cập nhật trạng thái ride request (có kiểm tra để tránh ghi đè trạng thái đã được tài xế nhận)
  Future<void> updateRideStatus(String requestId, RideStatus status) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('ride_requests').doc(requestId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) return;

        final currentStatus = snapshot.get('status') as String;

        // Nếu đã được chấp nhận hoặc đang đi, không cho phép quay lại trạng thái chờ/timeout
        if (currentStatus == RideStatus.accepted.name ||
            currentStatus == RideStatus.on_the_way.name ||
            currentStatus == RideStatus.ongoing.name ||
            currentStatus == RideStatus.completed.name) {
          if (status == RideStatus.timeout || status == RideStatus.cancelled) {
            debugPrint('[RideRepository] Từ chối cập nhật $status vì trạng thái hiện tại là $currentStatus');
            return;
          }
        }

        transaction.update(docRef, {'status': status.name});
      });
    } catch (e) {
      debugPrint('[RideRepository] Error updating ride status: $e');
    }
  }

  // Chấp nhận chuyến xe (cập nhật status + thông tin tài xế) - Sử dụng Transaction để an toàn
  Future<void> acceptRide(
    String requestId,
    String driverName,
    String driverPhone,
  ) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final DocumentReference rideRef = _firestore
            .collection('ride_requests')
            .doc(requestId);
        
        // Đọc trạng thái hiện tại
        final snapshot = await rideRef.get().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timeout khi đọc ride request'),
        );

        if (!snapshot.exists) {
          throw Exception('Chuyến xe không tồn tại.');
        }

        final String currentStatus = snapshot.get('status');
        // Chỉ cho phép "Chấp nhận" nếu đang ở trạng thái driver_assigned hoặc searching_driver
        if (currentStatus != RideStatus.driver_assigned.name &&
            currentStatus != RideStatus.searching_driver.name) {
          throw Exception(
            'Xin lỗi, chuyến xe này đã có người khác nhận hoặc đã bị hủy.',
          );
        }

        // Cập nhật trạng thái
        await rideRef.update({
          'status': RideStatus.accepted.name,
          'driverName': driverName,
          'driverPhone': driverPhone,
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timeout khi cập nhật ride request'),
        );

        debugPrint('[RideRepository] acceptRide thành công cho requestId: $requestId');
        return; // Thành công, thoát khỏi vòng lặp retry

      } catch (e) {
        debugPrint('[RideRepository] acceptRide lần $attempt thất bại: $e');
        if (attempt == maxRetries) {
          rethrow; // Hết số lần thử, throw lỗi ra ngoài
        }
        // Chờ 1 giây trước khi thử lại
        await Future.delayed(const Duration(seconds: 1));
      }
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
        .snapshots()
        .map(
          (snapshot) {
            final requests = snapshot.docs
              .map(
                (doc) => RideRequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((r) => r.status == RideStatus.driver_assigned) // Lọc trong Dart để tránh lỗi index
              .toList();
            
            // Sắp xếp lấy request mới nhất lên đầu
            requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return requests;
          },
        );
  }

  // Stream chuyến xe đang thực hiện (chỉ trong vòng 24h gần nhất)
  Stream<RideRequestModel?> watchActiveRide(String driverId) {
    // Chúng ta lắng nghe đồng thời cả ride_requests (cho các chuyến mới accept)
    // và trips (cho các chuyến đang thực hiện - ongoing)
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .asyncMap((snapshot) async {
          // 1. Tìm các request có trạng thái hoạt động
          final activeDocs = snapshot.docs.where((doc) {
            final status = (doc.data()['status'] as String?)?.toLowerCase() ?? '';
            return status == RideStatus.accepted.name || 
                   status == RideStatus.on_the_way.name || 
                   status == RideStatus.ongoing.name;
          }).toList();

          if (activeDocs.isNotEmpty) {
            print('DEBUG: [RideRepository] Tìm thấy ${activeDocs.length} active rides trong ride_requests');
            // Sắp xếp lấy chuyến mới nhất
            activeDocs.sort((a, b) {
              final aTime = a.get('createdAt') as Timestamp?;
              final bTime = b.get('createdAt') as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });
            return RideRequestModel.fromMap(activeDocs.first.data() as Map<String, dynamic>);
          }

          // 2. Nếu không thấy trong ride_requests, hãy kiểm tra collection 'trips' (phòng trường hợp đồng bộ chậm)
          final tripSnapshot = await _firestore
              .collection('trips')
              .where('driverId', isEqualTo: driverId)
              .get();

          final ongoingTrips = tripSnapshot.docs.where((doc) => doc.data()['status'] == 'ongoing').toList();

          if (ongoingTrips.isNotEmpty) {
            print('DEBUG: [RideRepository] Tìm thấy ongoing trip trong trips cho driver: $driverId');
            final tripId = ongoingTrips.first.id;
            final requestDoc = await _firestore.collection('ride_requests').doc(tripId).get();
            if (requestDoc.exists) {
              return RideRequestModel.fromMap(requestDoc.data() as Map<String, dynamic>);
            }
          }

          print('DEBUG: [RideRepository] Không tìm thấy bất kỳ active ride nào cho driver: $driverId');
          return null;
        });
  }

  // Stream chuyến xe đang thực hiện (Dành cho Customer)
  Stream<RideRequestModel?> watchActiveRideForCustomer(String customerId) {
    return _firestore
        .collection('ride_requests')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .asyncMap((snapshot) async {
      // 1. Tìm các request có trạng thái hoạt động
      final activeDocs = snapshot.docs.where((doc) {
        final status = (doc.data()['status'] as String?)?.toLowerCase() ?? '';
        return status == RideStatus.accepted.name ||
            status == RideStatus.on_the_way.name ||
            status == RideStatus.ongoing.name ||
            status == RideStatus.pending.name ||
            status == RideStatus.searching_driver.name ||
            status == RideStatus.driver_assigned.name;
      }).toList();

      if (activeDocs.isNotEmpty) {
        // Sắp xếp lấy chuyến mới nhất
        activeDocs.sort((a, b) {
          final aTime = a.get('createdAt') as Timestamp?;
          final bTime = b.get('createdAt') as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        return RideRequestModel.fromMap(
            activeDocs.first.data() as Map<String, dynamic>);
      }

      // 2. Nếu không thấy trong ride_requests, hãy kiểm tra collection 'trips'
      final tripSnapshot = await _firestore
          .collection('trips')
          .where('customerId', isEqualTo: customerId)
          .get();

      final ongoingTrips = tripSnapshot.docs.where((doc) => doc.data()['status'] == 'ongoing').toList();

      if (ongoingTrips.isNotEmpty) {
        final tripId = ongoingTrips.first.id;
        final requestDoc =
            await _firestore.collection('ride_requests').doc(tripId).get();
        if (requestDoc.exists) {
          return RideRequestModel.fromMap(
              requestDoc.data() as Map<String, dynamic>);
        }
      }

      return null;
    });
  }

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
