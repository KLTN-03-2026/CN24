import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:ride_now_khoaluan/controllers/auth_controller.dart';
import 'package:ride_now_khoaluan/models/ride_request_model.dart';
import 'package:ride_now_khoaluan/repositories/ride_repository.dart';
import 'package:ride_now_khoaluan/services/location_service.dart';
import 'package:ride_now_khoaluan/services/matching_service.dart';
import 'package:ride_now_khoaluan/services/ride_service.dart';
import 'package:ride_now_khoaluan/services/trackasia_service.dart';
import 'package:ride_now_khoaluan/models/user_model.dart';
import 'package:ride_now_khoaluan/services/firestore_service.dart';

class CustomerHomeController extends GetxController {
  final MapController mapController = MapController();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  final RideService _rideService = RideService();
  final MatchingService _matchingService = MatchingService();
  final LocationService _locationService = LocationService();
  final RideRepository _rideRepository = RideRepository();
  final AuthController _authController = Get.find<AuthController>();
  final TrackAsiaService _trackAsiaService = TrackAsiaService();
  final FirestoreService _firestoreService = FirestoreService();

  // Observable states
  var currentLocation = Rxn<LatLng>();
  var searchedPickupLocation = Rxn<LatLng>();
  final Rxn<RideRequestModel> activeRide = Rxn<RideRequestModel>();
  final Rxn<UserModel> assignedDriver = Rxn<UserModel>(); // Thêm biến lưu thông tin tài xế
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  var searchedLocation = Rxn<LatLng>();
  var pickupAddress = 'current_location'.tr.obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isFetchingInfo = false.obs;
  var isRouting = false.obs;
  var isSearchingPickup = true.obs;

  // Route state
  var routePoints = <LatLng>[].obs;
  var previewDistance = Rxn<double>();
  var previewDuration = Rxn<double>();

  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _rideRequestSubscription;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _startLocationTracking();
    _startWatchingActiveRide();
  }

  @override
  void onClose() {
    _driverLocationSubscription?.cancel();
    _rideRequestSubscription?.cancel();
    pickupController.dispose();
    destinationController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> _startLocationTracking() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      
      // Update map camera
      Future.delayed(const Duration(milliseconds: 500), () {
        mapController.move(currentLocation.value!, 15);
      });
      
      _locationService.getPositionStream().listen((pos) {
        currentLocation.value = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lấy vị trí: $e');
    }
  }

  void _startWatchingActiveRide() {
    final user = _authController.userModel;
    if (user == null) return;

    _rideRequestSubscription = _rideRepository.watchActiveRideForCustomer(user.id).listen((ride) {
      activeRide.value = ride;
      if (ride != null && (ride.status == RideStatus.accepted || ride.status == RideStatus.ongoing || ride.status == RideStatus.on_the_way)) {
        _startWatchingDriverLocation(ride.driverId!);
        _fetchAssignedDriver(ride.driverId!); // Tải thông tin tài xế
      } else {
        _driverLocationSubscription?.cancel();
        driverLocation.value = null;
        assignedDriver.value = null; // Xóa thông tin tài xế khi kết thúc
      }
    });
  }

  Future<void> _fetchAssignedDriver(String driverId) async {
    try {
      final driver = await _firestoreService.getUser(driverId);
      assignedDriver.value = driver;
    } catch (e) {
      debugPrint('Error fetching driver info: $e');
    }
  }

  void _startWatchingDriverLocation(String driverId) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _rideRepository.watchDriverLocation(driverId).listen((loc) {
      if (loc != null) {
        final newLoc = LatLng(loc.latitude, loc.longitude);
        driverLocation.value = newLoc;
        
        // Tự động fit camera để thấy cả khách và tài xế
        if (currentLocation.value != null) {
          final bounds = LatLngBounds.fromPoints([currentLocation.value!, newLoc]);
          mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
        }
      }
    });
  }

  void onSearchChanged(String query, bool isPickup) {
    isSearchingPickup.value = isPickup;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        searchResults.clear();
        return;
      }
      try {
        final results = await _trackAsiaService.searchPlace(query);
        searchResults.assignAll(results);
      } catch (e) {
        print('Error searching: $e');
      }
    });
  }

  Future<void> selectLocation(Map<String, dynamic> place) async {
    final lat = (place['lat'] as num).toDouble();
    final lon = (place['lon'] as num).toDouble();
    final pos = LatLng(lat, lon);
    final address = place['display_name'] ?? '';

    if (isSearchingPickup.value) {
      searchedPickupLocation.value = pos;
      pickupController.text = address;
      pickupAddress.value = address;
    } else {
      searchedLocation.value = pos;
      destinationController.text = address;
    }
    
    searchResults.clear();
    mapController.move(pos, 15);
    
    // Chỉ cần có điểm đến (hoặc điểm đón mới) là tính toán đường đi ngay
    if (searchedLocation.value != null || searchedPickupLocation.value != null) {
      getRoute();
    }
  }

  Future<void> searchLocation(String query, bool isPickup) async {
    if (query.isEmpty) return;
    isSearchingPickup.value = isPickup;
    isLoading.value = true;
    try {
      final results = await _trackAsiaService.searchPlace(query);
      if (results.isNotEmpty) {
        await selectLocation(results.first);
      } else {
        Get.snackbar('Thông báo', 'Không tìm thấy địa điểm này');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Tìm kiếm thất bại: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getRoute() async {
    final start = searchedPickupLocation.value ?? currentLocation.value;
    final end = searchedLocation.value;
    if (start == null || end == null) return;

    isRouting.value = true;
    try {
      final route = await _trackAsiaService.getRoute(
        start.latitude, start.longitude,
        end.latitude, end.longitude,
      );
      
      if (route['points'] == null || (route['points'] as List).isEmpty) {
        throw Exception('Empty route points');
      }

      final List<dynamic> pointsData = route['points'];
      routePoints.assignAll(pointsData.map((p) => LatLng(p['lat'], p['lon'])).toList());
      previewDistance.value = route['distance'];
      previewDuration.value = route['duration'];
      
      // Fit bounds for flutter_map v7
      if (routePoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(routePoints);
        mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      }
    } catch (e) {
      debugPrint('Routing Error, using straight line: $e');
      // Fallback: Vẽ đường thẳng nếu không lấy được đường đi chi tiết
      routePoints.assignAll([start, end]);
      
      // Tính khoảng cách cơ bản (đường chim bay * 1.2 để bù trừ đường quanh co)
      final distance = const Distance().as(LengthUnit.Meter, start, end) / 1000 * 1.2;
      previewDistance.value = distance;
      previewDuration.value = distance * 2; // Giả định 2 phút/km
      
      Get.snackbar('Thông báo', 'Không thể lấy đường đi chi tiết, đang sử dụng ước tính đường thẳng.');
    } finally {
      isRouting.value = false;
    }
  }

  Future<void> handleBookRide() async {
    final start = searchedPickupLocation.value ?? currentLocation.value;
    final end = searchedLocation.value;
    if (start == null || end == null) return;

    isLoading.value = true;
    try {
      final user = _authController.userModel!;
      final ride = RideRequestModel(
        id: '',
        customerId: user.id,
        customerName: user.name, // Fixed: use name instead of fullName
        pickupAddress: pickupAddress.value,
        destinationAddress: destinationController.text,
        pickupLatitude: start.latitude,
        pickupLongitude: start.longitude,
        destinationLatitude: end.latitude,
        destinationLongitude: end.longitude,
        status: RideStatus.searching_driver,
        createdAt: DateTime.now(),
      );

      final rideId = await _rideService.createRideRequest(ride);
      final createdRide = ride.copyWith(id: rideId);
      
      // Start matching process in background
      _matchingService.findAndMatchDriver(createdRide).catchError((e) {
        debugPrint('[CustomerHomeController] Matching Error: $e');
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Đặt xe thất bại: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void swapLocations() {
    final tempPos = searchedPickupLocation.value;
    searchedPickupLocation.value = searchedLocation.value;
    searchedLocation.value = tempPos;

    final tempTxt = pickupController.text;
    pickupController.text = destinationController.text;
    destinationController.text = tempTxt;
    
    if (searchedPickupLocation.value != null && searchedLocation.value != null) {
      getRoute();
    }
  }
  
  String formatVND(double amount) => '${(amount / 1000).toStringAsFixed(0)}.000đ';
}
