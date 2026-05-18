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

      print('DEBUG: [MatchingService] Đang tìm kiếm tài xế gần nhất cho chuyến xe: ${request.id}');

      // 2. Lấy danh sách tài xế THỰC SỰ online từ bảng users (nguồn chuẩn)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('DEBUG: [MatchingService] Không tìm thấy tài xế nào online trong bảng users.');
        await _rideRepository.updateRideStatus(request.id, RideStatus.timeout);
        throw Exception('Không tìm thấy tài xế nào online.');
      }

      // Tập hợp ID tài xế thực sự online
      final onlineDriverIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      print('DEBUG: [MatchingService] Tài xế THỰC SỰ online (từ bảng users): $onlineDriverIds');

      // 3. Lấy vị trí từ driver_locations chỉ cho các tài xế đã xác nhận online
      List<Map<String, dynamic>> driversWithDistance = [];
      for (var driverId in onlineDriverIds) {
        final locDoc = await _firestore.collection('driver_locations').doc(driverId).get();
        if (locDoc.exists) {
          final driverLoc = DriverLocationModel.fromMap(locDoc.data()!);
          double dist = calculateDistance(
            request.pickupLatitude,
            request.pickupLongitude,
            driverLoc.latitude,
            driverLoc.longitude,
          );
          driversWithDistance.add({
            'driverId': driverId,
            'distance': dist,
          });
        }
      }

      if (driversWithDistance.isEmpty) {
        print('DEBUG: [MatchingService] Không tìm thấy vị trí cho bất kỳ tài xế online nào.');
        await _rideRepository.updateRideStatus(request.id, RideStatus.timeout);
        throw Exception('Không tìm thấy tài xế nào có vị trí.');
      }

      driversWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
      print('DEBUG: [MatchingService] Tìm thấy ${driversWithDistance.length} tài xế đang hoạt động.');
      print('DEBUG: [MatchingService] Danh sách tài xế ưu tiên: ${driversWithDistance.map((d) => "${d['driverId']} (${d['distance'].toStringAsFixed(2)}km)").toList()}');

      // 4. Lần lượt mời các tài xế
      for (var driver in driversWithDistance) {
        // KIỂM TRA TRƯỚC MỖI LẦN MỜI: Xem chuyến đi đã bị hủy chưa
        final currentRequest = await _rideRepository.getRideRequest(request.id);
        if (currentRequest == null || currentRequest.status == RideStatus.cancelled) {
          print('DEBUG: [MatchingService] Dừng tìm kiếm vì chuyến đi đã bị hủy hoặc không tồn tại.');
          return;
        }

        final driverId = driver['driverId'];
        print('DEBUG: [MatchingService] Đang kiểm tra trạng thái và mời tài xế: $driverId...');
        bool result = await _tryAssignDriver(request.id, driverId, driver['distance']);
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
        
        // Double-check trạng thái từ bảng users (nguồn chuẩn)
        bool isOnlineInDb = userData?['isOnline'] ?? false;
        bool isAvailableInDb = userData?['isAvailable'] ?? false;
        
        print('DEBUG: [MatchingService] Kiểm tra thực tế tài xế $driverId: isOnline=$isOnlineInDb, isAvailable=$isAvailableInDb');

        if (!isOnlineInDb || !isAvailableInDb) {
          print('DEBUG: [MatchingService] BỎ QUA tài xế $driverId vì trạng thái thực tế là Offline/Bận.');
          // Tự động đồng bộ lại bảng driver_locations
          await _firestore.collection('driver_locations').doc(driverId).set({
            'isOnline': isOnlineInDb,
            'isAvailable': isAvailableInDb,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return false;
        }

        driverPhone = userData?['phone'];
        driverName = userData?['name'];
      } else {
        // Tài xế không tồn tại trong bảng users (ghost driver) -> xoá khỏi driver_locations và bỏ qua
        print('DEBUG: [MatchingService] Tài xế $driverId không tồn tại trong users. Xoá khỏi driver_locations và bỏ qua.');
        await _firestore.collection('driver_locations').doc(driverId).delete();
        return false;
      }
    } catch (e) {
      print('Error fetching driver info: $e');
      return false; // Skip if we can't verify info
    }

    // 2. Gán tài xế kèm thông tin
    print('DEBUG: [MatchingService] Đang thông báo cho tài xế: ${driverName ?? driverId} (Khoảng cách: ${distance.toStringAsFixed(2)} km)');
    await _rideRepository.assignDriver(requestId, driverId, distance, driverPhone, driverName);
    print('DEBUG: [MatchingService] Đã gọi assignDriver cho requestId: $requestId');

    // Chờ phản hồi trong 5 phút (để dễ dàng test thủ công)
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
      } else if (updatedRequest.status == RideStatus.cancelled) {
        print('DEBUG: [MatchingService] Khách hàng đã hủy chuyến xe. Dừng chờ tài xế.');
        if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        subscription?.cancel();
      }
    });

    // Timeout handled by Future.wait or similar
    try {
       bool accepted = await responseCompleter.future.timeout(
        const Duration(minutes: 3),
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
