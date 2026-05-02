import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/ride_request_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../../services/location_service.dart';
import '../../../services/matching_service.dart';
import '../../../services/ride_service.dart';
import '../../../services/trackasia_service.dart';
import '../profiles/profile_view.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  final MapController _mapController = MapController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final RideService _rideService = RideService();
  final MatchingService _matchingService = MatchingService();
  final LocationService _locationService = LocationService();
  final RideRepository _rideRepository = RideRepository();
  final AuthController _authController = Get.find<AuthController>();
  final TrackAsiaService _trackAsiaService = TrackAsiaService();

  LatLng? currentLocation;
  LatLng? searchedPickupLocation;
  LatLng? searchedLocation;
  LatLng? driverLocation;
  String _pickupAddress = 'Vị trí hiện tại';
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _rideRequestSubscription;
  RideRequestModel? _activeRide;

  List<Map<String, dynamic>> searchResults = [];
  bool _isLoading = false;
  bool _isFetchingInfo = false;
  bool _isRouting = false;
  bool _isSearchingPickup =
      true; // Mặc định là tìm kiếm điểm đón khi click vào ô đón

  // Route state
  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;

  // Preview route info
  String? _previewDistance;
  String? _previewDuration;
  List<LatLng> _previewPoints = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();

    // Khôi phục chuyến xe đang thực hiện khi vào app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWatchingActiveRide();
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _rideRequestSubscription?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
        ),
      );
      final initial = LatLng(
        initialPosition.latitude,
        initialPosition.longitude,
      );
      if (mounted) {
        setState(() {
          currentLocation = initial;
          _pickupController.text = 'Vị trí của bạn';
          _pickupAddress = 'Vị trí của bạn';
        });
        _updatePickupAddress(initial);
        // Di chuyển map đến vị trí hiện tại
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(initial, 17);
        });
      }
    } catch (e) {
      debugPrint('Could not get initial position: $e');
    }

    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 2),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      final newLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        // Chỉ cập nhật địa chỉ nếu di chuyển quá 10m
        double distance = 0;
        if (currentLocation != null) {
          distance = Geolocator.distanceBetween(
            currentLocation!.latitude,
            currentLocation!.longitude,
            newLocation.latitude,
            newLocation.longitude,
          );
        }

        setState(() {
          currentLocation = newLocation;
        });

        if (distance > 10 || _pickupAddress == 'Vị trí hiện tại') {
          _updatePickupAddress(newLocation);
        }
      }
    });
  }

  void _startWatchingActiveRide() {
    final customerId = _authController.userModel?.id;
    if (customerId == null) return;

    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = _rideRepository
        .watchActiveRideForCustomer(customerId)
        .listen((request) {
      if (mounted) {
        setState(() {
          _activeRide = request;
        });
      }

      if (request != null) {
        // Nếu có tài xế nhận chuyến, bắt đầu theo dõi vị trí tài xế
        if (request.driverId != null && request.driverId!.isNotEmpty) {
          _startTrackingDriver(request.driverId!);
        }

        // Tự động đóng các dialog chờ nếu chuyến đã được nhận hoặc đang đi
        if (request.status == RideStatus.accepted ||
            request.status == RideStatus.on_the_way ||
            request.status == RideStatus.ongoing) {
          // No dialog to close anymore
        }
      }
    });
  }

  Future<void> _updatePickupAddress(LatLng location) async {
    try {
      final place = await _trackAsiaService.reverseGeocode(
        lat: location.latitude,
        lng: location.longitude,
      );
      if (place != null && mounted) {
        setState(() {
          _pickupAddress = place.label;
          if (searchedPickupLocation == null) {
            _pickupController.text = place.label;
          }
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  void _startTrackingDriver(String driverId) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _locationService
        .getDriverLocationStream(driverId)
        .listen((loc) {
          if (mounted) {
            setState(() {
              driverLocation = LatLng(loc.latitude, loc.longitude);
            });
          }
        });
  }

  void _listenToRideRequest(String requestId) {
    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = _rideRepository
        .watchRideRequest(requestId)
        .listen((request) {
          if (mounted) {
            setState(() {
              _activeRide = request;
            });
          }

          if (request.status == RideStatus.accepted &&
              request.driverId != null &&
              request.driverId!.isNotEmpty) {
            _startTrackingDriver(request.driverId!);
            Get.snackbar(
              'Tài xế đã nhận chuyến',
              'Tài xế đang đến điểm đón của bạn.',
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          } else if (request.status == RideStatus.completed) {
            _clearRoute();
          } else if (request.status == RideStatus.cancelled ||
              request.status == RideStatus.rejected ||
              request.status == RideStatus.timeout) {
            _stopTrackingDriver();
          }
        });
  }

  void _stopTrackingDriver() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = null;
    if (mounted) {
      setState(() {
        driverLocation = null;
        _activeRide = null;
      });
    }
  }

  void _onSearchChanged(String query, bool isPickup) {
    _isSearchingPickup = isPickup;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          searchResults = [];
          if (isPickup) {
            searchedPickupLocation = null;
          } else {
            searchedLocation = null;
          }
        });
        return;
      }

      if (!_trackAsiaService.hasValidKey) return;

      try {
        final results = await _trackAsiaService.autocomplete(
          query,
          lat: currentLocation?.latitude,
          lon: currentLocation?.longitude,
        );

        if (mounted) {
          setState(() {
            searchResults = results
                .map(
                  (p) => {
                    'display_name': p.label,
                    'lat': p.latitude,
                    'lon': p.longitude,
                  },
                )
                .toList();
          });
        }
      } catch (e) {
        debugPrint("Error in live search: $e");
      }
    });
  }

  Future<void> _searchLocation(String query, bool isPickup) async {
    if (query.isEmpty) return;
    _debounce?.cancel();
    _isSearchingPickup = isPickup;

    setState(() {
      _isLoading = true;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      if (isPickup) {
        searchedPickupLocation = null;
      } else {
        searchedLocation = null;
      }
      searchResults = [];
    });
    // ... logic phía dưới giữ nguyên cho API gọi ...

    if (!_trackAsiaService.hasValidKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có API Key. Hãy thử chạy app bằng lệnh: flutter run --dart-define=TRACKASIA_KEY=...',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Use searchAddress for the final query (submitted via button or Enter)
      // searchAddress is often more precise for full house numbers than autocomplete
      final result = await _trackAsiaService.searchAddress(
        query,
        lat: currentLocation?.latitude,
        lon: currentLocation?.longitude,
      );

      if (mounted) {
        if (result != null) {
          _selectLocation({
            'display_name': result.label,
            'lat': result.latitude,
            'lon': result.longitude,
          });
        } else {
          // Fallback to autocomplete if searchAddress returns null
          final results = await _trackAsiaService.autocomplete(
            query,
            lat: currentLocation?.latitude,
            lon: currentLocation?.longitude,
          );
          if (results.isNotEmpty) {
            setState(() {
              searchResults = results
                  .map(
                    (p) => {
                      'display_name': p.label,
                      'lat': p.latitude,
                      'lon': p.longitude,
                    },
                  )
                  .toList();
            });

            if (searchResults.length == 1) {
              _selectLocation(searchResults[0]);
            } else {
              _mapController.move(
                LatLng(results[0].latitude, results[0].longitude),
                15,
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy địa điểm.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error searching location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi tìm kiếm.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectLocation(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lon = result['lon'] as double;
    final newLocation = LatLng(lat, lon);
    final name = result['display_name'] ?? '';

    setState(() {
      if (_isSearchingPickup) {
        searchedPickupLocation = newLocation;
        _pickupAddress = name;
        _pickupController.text = name;
      } else {
        searchedLocation = newLocation;
        _destinationController.text = name;
      }
      searchResults = [];
    });

    _mapController.move(newLocation, 17);

    final start = searchedPickupLocation ?? currentLocation;
    final end = searchedLocation;

    if (start != null && end != null) {
      _fetchRouteInfo(start, end);
    }
  }

  Future<void> _fetchRouteInfo(LatLng origin, LatLng destination) async {
    if (mounted) setState(() => _isFetchingInfo = true);

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.ride_now_khoaluan'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          final points = coordinates.map<LatLng>((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final distanceKm = distanceMeters / 1000;
          final durationMin = (distanceKm / 35 * 60).round();

          final distanceStr = distanceKm >= 1
              ? '${distanceKm.toStringAsFixed(1)} km'
              : '${distanceMeters.round()} m';
          final durationStr = durationMin >= 60
              ? '${durationMin ~/ 60} giờ ${durationMin % 60} phút'
              : '$durationMin phút';

          if (mounted) {
            setState(() {
              _previewPoints = points;
              _previewDistance = distanceStr;
              _previewDuration = durationStr;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route info: $e');
    } finally {
      if (mounted) setState(() => _isFetchingInfo = false);
    }
  }

  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    setState(() {
      _isRouting = true;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });

    if (_previewPoints.isNotEmpty && _previewDistance != null) {
      final distanceKm = _parseDistance(_previewDistance);
      final durationMin = (distanceKm != null)
          ? (distanceKm / 35 * 60).round()
          : 0;

      if (mounted) {
        setState(() {
          _isRouting = false;
          _routePoints = _previewPoints;
          _routeDistance = _previewDistance;
          _routeDuration = durationMin >= 60
              ? '${durationMin ~/ 60} giờ ${durationMin % 60} phút'
              : '$durationMin phút';
        });
        if (_previewPoints.length > 1) {
          final bounds = LatLngBounds.fromPoints(_previewPoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
          );
        }
      }
      return;
    }
  }

  void _swapLocations() {
    setState(() {
      // Hoán đổi text trong controller
      final tempText = _pickupController.text;
      _pickupController.text = _destinationController.text;
      _destinationController.text = tempText;

      // Xác định vị trí đón và đến hiện tại
      final oldPickup = searchedPickupLocation ?? currentLocation;
      final oldDestination = searchedLocation;

      // Hoán đổi tọa độ
      searchedPickupLocation = oldDestination;
      searchedLocation = oldPickup;

      // Cập nhật địa chỉ đón
      _pickupAddress = _pickupController.text;

      // Nếu cả hai điểm đều có tọa độ, tính toán lại lộ trình
      if (searchedPickupLocation != null && searchedLocation != null) {
        _fetchRouteInfo(searchedPickupLocation!, searchedLocation!);
      } else if (searchedPickupLocation == null &&
          currentLocation != null &&
          searchedLocation != null) {
        _fetchRouteInfo(currentLocation!, searchedLocation!);
      } else {
        // Nếu thiếu một trong hai điểm, xóa lộ trình cũ
        _routePoints = [];
        _previewPoints = [];
        _previewDistance = null;
        _previewDuration = null;
      }
    });
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _previewPoints = [];
      _previewDistance = null;
      _previewDuration = null;
      searchedLocation = null;
      searchedPickupLocation = null;
      searchResults = [];
      _destinationController.clear();
      _pickupController.text = 'Vị trí của bạn'; // Hoặc xóa hẳn
      _pickupAddress = 'Vị trí của bạn';
      _activeRide = null;
      _stopTrackingDriver();
    });
  }

  Future<void> _handleCancelRide() async {
    if (_activeRide == null) return;
    final rideId = _activeRide!.id;
    try {
      // Thay vì _clearRoute(), ta chỉ dừng theo dõi và xóa _activeRide
      // để giữ lại điểm đón/đến cho người dùng đặt lại nếu muốn
      setState(() {
        _activeRide = null;
        _stopTrackingDriver();
      });
      
      await _rideService.cancelRideRequest(rideId);
      Get.snackbar('Thông báo', 'Đã hủy chuyến xe.');
    } catch (e) {
      debugPrint('Error cancelling ride: $e');
      Get.snackbar('Lỗi', 'Không thể hủy chuyến: $e');
    }
  }

  Future<void> _handleBookRide() async {
    final start = searchedPickupLocation ?? currentLocation;
    if (start == null || searchedLocation == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn đầy đủ điểm đón và điểm đến.');
      return;
    }

    try {
      final userModel = _authController.userModel;
      if (userModel == null) throw Exception('Bạn cần đăng nhập để đặt xe.');

      final distanceKm =
          _parseDistance(_routeDistance) ?? _parseDistance(_previewDistance);

      final rideRequest = RideRequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: userModel.id,
        customerName: userModel.name,
        pickupAddress: _pickupAddress,
        pickupLatitude: start.latitude,
        pickupLongitude: start.longitude,
        destinationAddress: _destinationController.text,
        destinationLatitude: searchedLocation!.latitude,
        destinationLongitude: searchedLocation!.longitude,
        distanceInKm: distanceKm,
        fare: _calculateFare(distanceKm),
        status: RideStatus.pending,
        customerPhone: userModel.phone,
        createdAt: DateTime.now(),
      );

      await _rideService.createRideRequestDirectly(rideRequest);
      _listenToRideRequest(rideRequest.id);
      await _matchingService.findAndMatchDriver(rideRequest);

      Get.snackbar(
        'Thành công',
        'Tài xế đã nhận chuyến!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // No dialog to close anymore
      
      // Kiểm tra lại trạng thái thực tế trên Firestore trước khi xoá sạch state
      // Tránh trường hợp Race Condition: Tài xế vừa Accept thì Matching logic lại Timeout
      if (_activeRide != null) {
        final rideId = _activeRide!.id;
        final latestRequest = await _rideRepository.getRideRequest(rideId);
        if (latestRequest != null && 
            (latestRequest.status == RideStatus.accepted || 
             latestRequest.status == RideStatus.ongoing)) {
          // Nếu thực tế đã được nhận, thì không xoá state và để _listenToRideRequest xử lý
          debugPrint('[CustomerHomeView] Race Condition detected: Driver accepted but matching timed out. Recovering...');
          return;
        }
        
        // Nếu thực sự là lỗi/timeout, mới huỷ request
        _rideService.cancelRideRequest(rideId);
      }

      setState(() {
        _activeRide = null;
        _stopTrackingDriver();
      });

      Get.snackbar(
        'Thông báo',
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  double? _parseDistance(String? distStr) {
    if (distStr == null) return null;
    if (distStr.contains('km')) {
      return double.tryParse(distStr.replaceAll(' km', '').trim());
    } else if (distStr.contains('m')) {
      final meters = double.tryParse(distStr.replaceAll(' m', '').trim());
      if (meters != null) return meters / 1000;
    }
    return null;
  }

  String _formatVND(double? amount) {
    if (amount == null) return '0 VND';
    final String str = amount.round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} VND';
  }

  double? _calculateFare(double? distanceInKm) {
    if (distanceInKm == null) return null;
    double fare = 0;
    if (distanceInKm <= 2) {
      fare = distanceInKm * 10000;
    } else {
      fare = (2 * 10000) + ((distanceInKm - 2) * 9000);
    }
    return fare;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (searchedPickupLocation != null) {
      markers.add(
        Marker(
          point: searchedPickupLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.circle, color: Colors.green, size: 20),
        ),
      );
    }

    if (searchedLocation != null) {
      markers.add(
        Marker(
          point: searchedLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    if (searchResults.isNotEmpty && searchedLocation == null) {
      for (int i = 0; i < searchResults.length; i++) {
        final result = searchResults[i];
        final lat = result['lat'] as double;
        final lon = result['lon'] as double;
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _selectLocation(result),
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
          ),
        );
      }
    }

    if (driverLocation != null) {
      markers.add(
        Marker(
          point: driverLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.local_taxi, color: Colors.orange, size: 36),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(16.0544, 108.2022),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ride_now_khoaluan',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8,
                        color: const Color(0xFF1976D2),
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          Positioned(
            top: 50,
            left: 15,
            right: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pick up field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _pickupController,
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập điểm đón ...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onChanged: (val) =>
                                        _onSearchChanged(val, true),
                                    onSubmitted: (val) =>
                                        _searchLocation(val, true),
                                  ),
                                ),
                                if (_pickupController.text.isNotEmpty)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _pickupController.clear();
                                        searchedPickupLocation = null;
                                      });
                                    },
                                  ),
                                // const SizedBox(width: 10), // Space for swap button
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Destination field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _destinationController,
                                    decoration: const InputDecoration(
                                      hintText: 'Bạn muốn đi đâu ...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onChanged: (val) =>
                                        _onSearchChanged(val, false),
                                    onSubmitted: (val) =>
                                        _searchLocation(val, false),
                                  ),
                                ),
                                if (_isLoading || _isRouting)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (_destinationController.text.isNotEmpty)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _destinationController.clear();
                                        searchedLocation = null;
                                      });
                                    },
                                  )
                                else
                                  const Icon(
                                    Icons.search,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                const SizedBox(width: 10), // Space for swap button
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 15,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            onPressed: _swapLocations,
                            icon: const Icon(
                              Icons.swap_vert,
                              color: Colors.blue,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (searchResults.isNotEmpty && searchedLocation == null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final result = searchResults[index];
                        final name =
                            result['display_name'] ?? 'Địa chỉ không xác định';
                        return ListTile(
                          leading:
                              const Icon(Icons.location_on, color: Colors.red),
                          title: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectLocation(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            top: 50,
            right: 15,
            child: GestureDetector(
              onTap: () {
                Get.to(() => const ProfileView());
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.blue, size: 24),
              ),
            ),
          ),

          if (currentLocation != null)
            Positioned(
              bottom: _routePoints.isNotEmpty
                  ? 160
                  : searchedLocation != null
                  ? 140
                  : 30,
              right: 15,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  _mapController.move(currentLocation!, 17);
                },
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

          if (_activeRide != null ||
              _routePoints.isNotEmpty ||
              searchedLocation != null)
            DraggableScrollableSheet(
              initialChildSize: _activeRide != null ? 0.35 : 0.35,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (_activeRide != null)
                          () {
                            if (_activeRide!.status == RideStatus.accepted ||
                                _activeRide!.status == RideStatus.on_the_way ||
                                _activeRide!.status == RideStatus.ongoing) {
                              return _buildActiveRidePanel();
                            } else if (_activeRide!.status == RideStatus.pending ||
                                _activeRide!.status == RideStatus.searching_driver ||
                                _activeRide!.status == RideStatus.driver_assigned) {
                              return _buildSearchingPanel();
                            }
                            return const SizedBox.shrink();
                          }()
                        else if (_routePoints.isNotEmpty)
                          _buildRouteInfoPanel()
                        else if (searchedLocation != null)
                          _buildDestinationPanel(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _pickupAddress,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _destinationController.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _clearRoute,
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ],
          ),
          if (_isFetchingInfo)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else if (_previewDistance != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _RouteInfoTile(
                      icon: Icons.straighten,
                      label: 'Khoảng cách',
                      value: _previewDistance!,
                      iconColor: const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RouteInfoTile(
                      icon: Icons.access_time,
                      label: 'Thời gian',
                      value: _previewDuration!,
                      iconColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RouteInfoTile(
                      icon: Icons.payments,
                      label: 'Giá dự kiến',
                      value: _formatVND(
                        _calculateFare(_parseDistance(_previewDistance)),
                      ),
                      iconColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (currentLocation == null || _isRouting)
                      ? null
                      : () => _getRoute(currentLocation!, searchedLocation!),
                  icon: _isRouting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions, size: 18),
                  label: Text(_isRouting ? 'Đang tải...' : 'Đường đi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleBookRide,
                  icon: const Icon(Icons.local_taxi, size: 18),
                  label: const Text('Đặt xe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RouteInfoTile(
                  icon: Icons.straighten,
                  label: 'Khoảng cách',
                  value: _routeDistance!,
                  iconColor: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RouteInfoTile(
                  icon: Icons.access_time,
                  label: 'Thời gian',
                  value: _routeDuration!,
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RouteInfoTile(
                  icon: Icons.payments,
                  label: 'Giá tiền',
                  value: _formatVND(
                    _calculateFare(_parseDistance(_routeDistance)),
                  ),
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _clearRoute,
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleBookRide,
              icon: const Icon(Icons.local_taxi),
              label: const Text('Đặt xe ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRidePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.person, color: Colors.blue, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_activeRide!.status == RideStatus.on_the_way || 
                       _activeRide!.status == RideStatus.ongoing)
                          ? 'Đang trong chuyến đi'
                          : 'Tài xế đang đến',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _activeRide!.driverName ?? 'Tài xế của bạn',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatVND(_activeRide!.fare),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleCancelRide,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hủy chuyến',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_activeRide?.driverPhone != null) {
                      launchUrlString('tel:${_activeRide!.driverPhone}');
                    } else {
                      Get.snackbar(
                        'Thông báo',
                        'Không có số điện thoại tài xế.',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Gọi tài xế'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang tìm tài xế gần bạn...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _activeRide?.pickupAddress ?? '...',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: SizedBox(
                    height: 15,
                    child: VerticalDivider(width: 1, color: Colors.grey),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _activeRide?.destinationAddress ?? '...',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleCancelRide,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hủy yêu cầu',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _RouteInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
