import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_location_model.dart';
import '../models/ride_request_model.dart';
import '../repositories/ride_repository.dart';

class MatchingService {
  final RideRepository _rideRepository = RideRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thuật toán Haversine
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Tìm và khớp tài xế
  Future<void> findAndMatchDriver(RideRequestModel request) async {
    try {
      // 1. Cập nhật trạng thái đang tìm kiếm
      await _rideRepository.updateRideStatus(request.id, RideStatus.searching_driver);

      // 2. Lấy danh sách tài xế online & available
      print('DEBUG: [MatchingService] Đang tìm kiếm tài xế gần nhất cho chuyến xe: ${request.id}');
      final driverSnapshot = await _firestore
          .collection('driver_locations')
          .where('isOnline', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (driverSnapshot.docs.isEmpty) {
        print('DEBUG: [MatchingService] Không tìm thấy tài xế nào online trong driver_locations.');
        await _rideRepository.updateRideStatus(request.id, RideStatus.timeout);
        throw Exception('Không tìm thấy tài xế nào online.');
      }

      print('DEBUG: [MatchingService] Tìm thấy ${driverSnapshot.docs.length} tài xế đang hoạt động.');

      // 3. Tính khoảng cách và sắp xếp
      List<Map<String, dynamic>> driversWithDistance = [];
      for (var doc in driverSnapshot.docs) {
        final driverLoc = DriverLocationModel.fromMap(doc.data());
        double dist = calculateDistance(
          request.pickupLatitude,
          request.pickupLongitude,
          driverLoc.latitude,
          driverLoc.longitude,
        );
        driversWithDistance.add({
          'driverId': driverLoc.driverId,
          'distance': dist,
        });
      }

      driversWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
      print('DEBUG: [MatchingService] Danh sách tài xế ưu tiên: ${driversWithDistance.map((d) => "${d['driverId']} (${d['distance'].toStringAsFixed(2)}km)").toList()}');

      // 4. Thử từng tài xế một
      for (var driver in driversWithDistance) {
        print('DEBUG: [MatchingService] Thử mời tài xế: ${driver['driverId']}...');
        bool result = await _tryAssignDriver(request.id, driver['driverId'], driver['distance']);
        if (result) {
          print('DEBUG: [MatchingService] CHÚC MỪNG: Tài xế ${driver['driverId']} đã nhận chuyến.');
          return; 
        } else {
          print('DEBUG: [MatchingService] Tài xế ${driver['driverId']} không phản hồi hoặc đã từ chối.');
        }
      }

      // 5. Nếu không ai nhận
      await _rideRepository.updateRideStatus(request.id, RideStatus.timeout);
      throw Exception('Tất cả tài xế đều bận hoặc không phản hồi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _tryAssignDriver(String requestId, String driverId, double distance) async {
    // 1. Lấy thông tin tài xế từ collection 'users'
    String? driverPhone;
    String? driverName;
    try {
      final userDoc = await _firestore.collection('users').doc(driverId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        driverPhone = userData?['phone'];
        driverName = userData?['name'];
      }
    } catch (e) {
      print('Error fetching driver info: $e');
    }

    // 2. Gán tài xế kèm thông tin
    print('DEBUG: [MatchingService] Đang thông báo cho tài xế: ${driverName ?? driverId} (Khoảng cách: ${distance.toStringAsFixed(2)} km)');
    await _rideRepository.assignDriver(requestId, driverId, distance, driverPhone, driverName);

    // Chờ phản hồi trong 10 giây (điều chỉnh từ 15)
    Completer<bool> responseCompleter = Completer<bool>();
    
    StreamSubscription? subscription;
    subscription = _rideRepository.watchRideRequest(requestId).listen((updatedRequest) {
      if (updatedRequest.status == RideStatus.accepted) {
        print('DEBUG: [MatchingService] Tài xế $driverId đã trả lời: CHẤP NHẬN');
        if (!responseCompleter.isCompleted) responseCompleter.complete(true);
        subscription?.cancel();
      } else if (updatedRequest.status == RideStatus.rejected) {
        print('DEBUG: [MatchingService] Tài xế $driverId đã trả lời: TỪ CHỐI');
        if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        subscription?.cancel();
      }
    });

    // Timeout handled by Future.wait or similar
    try {
       bool accepted = await responseCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('DEBUG: [MatchingService] Tài xế $driverId: HẾT THỜI GIAN phản hồi (Timeout)');
          subscription?.cancel();
          return false;
        },
      );
      return accepted;
    } catch (e) {
      return false;
    }
  }
}
