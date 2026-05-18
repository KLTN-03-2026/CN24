import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../models/ride_request_model.dart';
import '../models/trip_model.dart';
import '../models/complaint_model.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload tệp lên Firebase Storage và trả về danh sách URL
  Future<List<String>> uploadFiles(List<File> files, String path) async {
    List<String> downloadUrls = [];
    for (var file in files) {
      try {
        // Lấy tên file an toàn
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
        final ref = _storage.ref().child(path).child(fileName);

        // Đọc tệp thành bytes để upload (tránh lỗi đường dẫn cục bộ)
        final bytes = await file.readAsBytes();

        // Upload và đợi hoàn tất
        final uploadTask = await ref.putData(bytes);

        // Lấy URL sau khi đã upload thành công
        final url = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('Firebase Storage Error: $e');
        rethrow; // Ném lỗi để UI hiển thị thông báo chi tiết hơn
      }
    }
    return downloadUrls;
  }

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

  // Cập nhật trạng thái ride request
  Future<void> updateRideStatus(
    String requestId, 
    RideStatus status, {
    String? driverId,
    String? driverName,
  }) async {
    try {
      final docRef = _firestore.collection('ride_requests').doc(requestId);
      final Map<String, dynamic> data = {'status': status.name};
      if (driverId != null) data['driverId'] = driverId;
      if (driverName != null) data['driverName'] = driverName;

      await _firestore.runTransaction((transaction) async {
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

        transaction.update(docRef, data);
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
            final rideMap = activeDocs.first.data() as Map<String, dynamic>;
            rideMap['id'] = activeDocs.first.id;
            return RideRequestModel.fromMap(rideMap);
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
        final rideMap = activeDocs.first.data() as Map<String, dynamic>;
        rideMap['id'] = activeDocs.first.id;
        return RideRequestModel.fromMap(rideMap);
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

  // Hoàn thành chuyến xe, cập nhật trip đã tồn tại và tạo thông báo đánh giá
  Future<void> completeRide(
    String requestId, [
    Map<String, dynamic>? updateData,
  ]) async {
    final WriteBatch batch = _firestore.batch();

    // 1. Lấy thông tin chuyến xe để biết customerId và driverId
    final rideDoc = await _firestore.collection('ride_requests').doc(requestId).get();
    if (!rideDoc.exists) {
      debugPrint('[RideRepository] completeRide: ride request $requestId not found');
      return;
    }
    
    final rideData = rideDoc.data() as Map<String, dynamic>;
    final customerId = rideData['customerId'] as String;
    final driverId = rideData['driverId'] as String;
    final driverName = rideData['driverName'] as String? ?? 'Tài xế';

    debugPrint('[RideRepository] completeRide: Creating notification for customer $customerId');

    // 2. Cập nhật trạng thái ride request
    batch.update(_firestore.collection('ride_requests').doc(requestId), {
      'status': RideStatus.completed.name,
    });

    // 3. Cập nhật hoặc tạo trip (dùng set merge để tránh lỗi NOT_FOUND nếu trip chưa tồn tại)
    final tripRef = _firestore.collection('trips').doc(requestId);
    final tripDoc = await tripRef.get();

    final safeUpdateData = {
      'status': 'completed',
      'completedAt': Timestamp.fromDate(DateTime.now()),
      ...?(updateData),
    };

    if (tripDoc.exists) {
      // Trip đã tồn tại → chỉ update
      batch.update(tripRef, safeUpdateData);
    } else {
      // Trip chưa tồn tại → tạo mới từ dữ liệu ride_request
      debugPrint('[RideRepository] completeRide: Trip chưa tồn tại, tạo mới từ ride_request');
      final tripData = {
        'id': requestId,
        'customerId': customerId,
        'customerName': rideData['customerName'] ?? '',
        'driverId': driverId,
        'driverName': driverName,
        'pickupAddress': rideData['pickupAddress'] ?? '',
        'pickupLatitude': rideData['pickupLatitude'] ?? 0.0,
        'pickupLongitude': rideData['pickupLongitude'] ?? 0.0,
        'destinationAddress': rideData['destinationAddress'] ?? '',
        'destinationLatitude': rideData['destinationLatitude'] ?? 0.0,
        'destinationLongitude': rideData['destinationLongitude'] ?? 0.0,
        'fare': rideData['fare'] ?? 0,
        'distance': rideData['distanceInKm'] ?? 0,
        'paymentMethod': rideData['paymentMethod'] ?? 'Tiền mặt',
        'createdAt': rideData['createdAt'] ?? Timestamp.fromDate(DateTime.now()),
        ...safeUpdateData,
      };
      batch.set(tripRef, tripData);
    }

    // 4. Tạo thông báo đánh giá cho khách hàng
    final notificationId = 'notif_$requestId';
    batch.set(_firestore.collection('notifications').doc(notificationId), {
      'id': notificationId,
      'userId': customerId,
      'rideId': requestId,
      'driverId': driverId,
      'driverName': driverName,
      'title': 'Đánh giá chuyến đi',
      'message': 'Chuyến đi cùng tài xế $driverName đã hoàn thành. Hãy chia sẻ trải nghiệm của bạn!',
      'type': 'rating',
      'isRated': false,
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Gửi đánh giá tài xế
  Future<void> submitRating({
    required String rideId,
    required String driverId,
    required double rating,
    required String feedback,
    required String notificationId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. ĐỌC: Lấy thông tin tài xế trước
        final driverRef = _firestore.collection('users').doc(driverId);
        final driverSnap = await transaction.get(driverRef);

        // 2. ĐỌC: Lấy thông tin chuyến đi để có customerId/Name
        final tripRef = _firestore.collection('trips').doc(rideId);
        final tripSnap = await transaction.get(tripRef);
        final tripData = tripSnap.data() as Map<String, dynamic>? ?? {};
        
        final String customerId = tripData['customerId'] ?? '';
        final String customerName = tripData['customerName'] ?? 'Khách hàng';
        final String drvName = tripData['driverName'] ?? 'Tài xế';

        // 3. GHI: Cập nhật Trip document
        transaction.update(tripRef, {
          'rating': rating,
          'feedback': feedback,
        });

        // 4. GHI: Tạo bản ghi Review chính thức
        final reviewRef = _firestore.collection('reviews').doc('rev_$rideId');
        transaction.set(reviewRef, {
          'id': 'rev_$rideId',
          'tripId': rideId,
          'customerId': customerId,
          'customerID': customerId, // Standardized field
          'customerName': customerName,
          'username': customerName,   // Standardized field
          'driverId': driverId,
          'driverID': driverId,     // Standardized field
          'driverName': drvName,
          'name': drvName,          // Standardized field (driver name)
          'rating': rating,
          'comment': feedback,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // 5. GHI: Cập nhật thống kê tài xế & Gửi thông báo cho tài xế
        if (driverSnap.exists) {
          final driverData = driverSnap.data() as Map<String, dynamic>;
          
          // Lấy rating hiện tại và số lượng đánh giá
          final double currentRating = (driverData['rating'] as num?)?.toDouble() ?? 0.0;
          
          // Ưu tiên dùng ratingCount, nếu chưa có thì dùng totalTrips
          int currentRatingCount = 0;
          if (driverData.containsKey('ratingCount')) {
            currentRatingCount = driverData['ratingCount'] as int? ?? 0;
          }

          final int newRatingCount = currentRatingCount + 1;
          
          // Công thức tính trung bình cộng: ((Cũ * Số lượng cũ) + Mới) / Số lượng mới
          final double newRating = ((currentRating * currentRatingCount) + rating) / newRatingCount;

          transaction.update(driverRef, {
            'rating': newRating,
            'ratingCount': newRatingCount,
          });

          // 6. GHI: Tạo thông báo cho tài xế về đánh giá mới
          final driverNotifId = 'notif_rating_$rideId';
          final feedbackText = feedback.isNotEmpty 
              ? '\nNhận xét: "$feedback"' 
              : '';
          transaction.set(_firestore.collection('notifications').doc(driverNotifId), {
            'id': driverNotifId,
            'userId': driverId,
            'rideId': rideId,
            'customerId': customerId,
            'customerName': customerName,
            'driverId': driverId,
            'name': drvName,
            'title': 'Bạn nhận được đánh giá ${rating.toStringAsFixed(1)} ⭐',
            'message': 'Khách hàng đã đánh giá bạn ${rating.toStringAsFixed(1)} sao cho chuyến đi vừa rồi.$feedbackText',
            'type': 'info', // Changed from 'rating' to 'info' to prevent driver from rating back
            'isRead': false,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        // 5. GHI: Cập nhật thông báo của khách hàng đã hoàn thành
        final notifRef = _firestore.collection('notifications').doc(notificationId);
        transaction.update(notifRef, {
          'isRated': true,
          'isRead': true,
        });
      });
    } catch (e) {
      debugPrint('[RideRepository] submitRating error: $e');
      rethrow;
    }
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

  // Cập nhật trạng thái online của tài xế
  Future<void> updateDriverOnlineStatus(String driverId, bool isOnline) async {
    await _firestore.collection('users').doc(driverId).update({
      'isOnline': isOnline,
    });
  }

  // Lắng nghe vị trí tài xế
  Stream<GeoPoint?> watchDriverLocation(String driverId) {
    return _firestore.collection('users').doc(driverId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      if (data['latitude'] != null && data['longitude'] != null) {
        return GeoPoint(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
      return null;
    });
  }

  // Từ chối chuyến xe
  Future<void> declineRide(String requestId, String driverId) async {
    await _firestore.collection('ride_requests').doc(requestId).update({
      'status': RideStatus.rejected.name,
      'driverId': null, // Reset driverId để hệ thống tìm tài xế khác (nếu cần)
    });
  }


  // Gửi khiếu nại
  Future<void> submitComplaint(ComplaintModel complaint) async {
    try {
      await _firestore
          .collection('complaints')
          .doc(complaint.id)
          .set(complaint.toMap());
    } catch (e) {
      debugPrint('[RideRepository] submitComplaint error: $e');
      rethrow;
    }
  }

  // Lấy danh sách khiếu nại của một user
  Stream<List<ComplaintModel>> getComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sắp xếp thủ công theo thời gian giảm dần (mới nhất lên đầu)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
