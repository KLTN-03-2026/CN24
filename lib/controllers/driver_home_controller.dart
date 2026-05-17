import 'dart:async';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/ride_request_model.dart';
import 'package:ride_now_khoaluan/repositories/ride_repository.dart';
import 'package:ride_now_khoaluan/services/location_service.dart';

class DriverHomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final LocationService _locationService = LocationService();
  final RideRepository _rideRepository = RideRepository();

  var isOnline = false.obs;
  var currentRequest = Rxn<RideRequestModel>();
  var activeRide = Rxn<RideRequestModel>();

  StreamSubscription? _requestSubscription;
  StreamSubscription? _activeRideSubscription;

  @override
  void onInit() {
    super.onInit();
    
    // Sync online status with userModel
    ever(_authController.userModelRx, (user) {
      if (user != null) {
        isOnline.value = user.isOnline ?? false;
        if (isOnline.value) {
          _startDriverServices();
        } else {
          _stopDriverServices();
        }
        _startWatchingActiveRide(user.id);
      }
    });

    final user = _authController.userModel;
    if (user != null) {
      isOnline.value = user.isOnline ?? false;
      if (isOnline.value) _startDriverServices();
      _startWatchingActiveRide(user.id);
    }
  }

  @override
  void onClose() {
    _stopDriverServices();
    super.onClose();
  }

  void _startDriverServices() {
    final driverId = _authController.userModel?.id;
    if (driverId == null) return;

    _locationService.startDriverLocationUpdates(driverId);

    _requestSubscription?.cancel();
    _requestSubscription = _rideRepository.watchIncomingRequests(driverId).listen((requests) {
      if (requests.isNotEmpty) {
        currentRequest.value = requests.first;
      } else {
        currentRequest.value = null;
      }
    });
  }

  void _stopDriverServices() {
    _locationService.stopDriverLocationUpdates();
    _requestSubscription?.cancel();
    _activeRideSubscription?.cancel();
  }

  void _startWatchingActiveRide(String driverId) {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = _rideRepository.watchActiveRide(driverId).listen((ride) {
      activeRide.value = ride;
    });
  }

  Future<void> toggleOnlineStatus() async {
    final user = _authController.userModel;
    if (user == null) return;

    final newStatus = !isOnline.value;
    try {
      await _rideRepository.updateDriverOnlineStatus(user.id, newStatus);
      isOnline.value = newStatus;
      if (newStatus) _startDriverServices();
      else _stopDriverServices();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái: $e');
    }
  }

  Future<void> acceptRide(String rideId) async {
    try {
      await _rideRepository.updateRideStatus(rideId, RideStatus.accepted, driverId: _authController.userModel!.id, driverName: _authController.userModel!.name);
      currentRequest.value = null;
    } catch (e) {
      Get.snackbar('Lỗi', 'Chấp nhận chuyến xe thất bại: $e');
    }
  }

  Future<void> declineRide(String rideId) async {
    try {
      await _rideRepository.declineRide(rideId, _authController.userModel!.id);
      currentRequest.value = null;
    } catch (e) {
      Get.snackbar('Lỗi', 'Từ chối chuyến xe thất bại: $e');
    }
  }
}
