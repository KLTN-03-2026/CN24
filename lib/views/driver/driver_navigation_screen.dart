import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/ride_request_model.dart';
import '../../services/location_service.dart';

class DriverNavigationScreen extends StatefulWidget {
  final RideRequestModel activeRide;

  const DriverNavigationScreen({super.key, required this.activeRide});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _driverLocation;
  List<LatLng> _routePoints = [];
  String? _distance;
  String? _duration;
  bool _isLoadingRoute = false;
  bool _isFirstLoad = true;

  // Customer route (pickup → destination)
  List<LatLng> _customerRoutePoints = [];
  String? _customerDistance;
  String? _customerDuration;
  bool _isLoadingCustomerRoute = false;
  bool _showCustomerRoute = false;

  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    // _initLocation() will be called after build or manually
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // Lấy vị trí hiện tại ban đầu
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
        ),
      );
      final initial = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _driverLocation = initial);
        try {
          _mapController.move(initial, 15);
        } catch (e) {
          debugPrint('DriverNav: error moving map initially: $e');
        }
        _fetchRoute(initial);
      }
    } catch (e) {
      debugPrint('DriverNav: error getting location: $e');
    }

    // Lắng nghe cập nhật vị trí realtime
    final locationSettings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            forceLocationManager: true,
            intervalDuration: const Duration(seconds: 3),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) {
            final curr = LatLng(pos.latitude, pos.longitude);
            if (mounted) {
              setState(() => _driverLocation = curr);
              // Cập nhật route mỗi khi di chuyển đủ xa
              _fetchRoute(curr);
            }
          },
        );
  }

  Future<void> _fetchRoute(LatLng origin) async {
    final pickup = LatLng(
      widget.activeRide.pickupLatitude,
      widget.activeRide.pickupLongitude,
    );

    setState(() => _isLoadingRoute = true);

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${pickup.longitude},${pickup.latitude}'
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
          // Tốc độ xe máy trung bình: 35 km/h
          final durationMin = (distanceKm / 35 * 60).round();

          final distanceStr = distanceKm >= 1
              ? '${distanceKm.toStringAsFixed(1)} km'
              : '${distanceMeters.round()} m';
          final durationStr = durationMin >= 60
              ? '${durationMin ~/ 60} giờ ${durationMin % 60} phút'
              : '$durationMin phút';

          if (mounted) {
            setState(() {
              _routePoints = points;
              _distance = distanceStr;
              _duration = durationStr;
            });

            // Chỉ fit camera lần đầu tiên, sau đó để user tự do kéo map
            if (_isFirstLoad && points.length > 1) {
              _isFirstLoad = false;
              try {
                final bounds = LatLngBounds.fromPoints(points);
                _mapController.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                );
              } catch (e) {
                debugPrint('DriverNav: fitBounds error: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DriverNav: error fetching route: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Lấy lộ trình của khách hàng (pickup → destination)
  Future<void> _fetchCustomerRoute() async {
    final pickup = LatLng(
      widget.activeRide.pickupLatitude,
      widget.activeRide.pickupLongitude,
    );
    final destination = LatLng(
      widget.activeRide.destinationLatitude,
      widget.activeRide.destinationLongitude,
    );

    setState(() => _isLoadingCustomerRoute = true);

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '${pickup.longitude},${pickup.latitude};'
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
              _customerRoutePoints = points;
              _customerDistance = distanceStr;
              _customerDuration = durationStr;
            });

            // Fit camera
            if (points.length > 1) {
              try {
                final bounds = LatLngBounds.fromPoints(points);
                _mapController.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                );
              } catch (e) {
                debugPrint('DriverNav: fitBounds customer route error: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DriverNav: error fetching customer route: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCustomerRoute = false);
    }
  }

  // ── Build markers cho FlutterMap ─────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final pickup = LatLng(
      widget.activeRide.pickupLatitude,
      widget.activeRide.pickupLongitude,
    );
    final destination = LatLng(
      widget.activeRide.destinationLatitude,
      widget.activeRide.destinationLongitude,
    );

    // Marker driver (nếu có vị trí)
    if (_driverLocation != null) {
      markers.add(Marker(
        point: _driverLocation!,
        width: 40,
        height: 40,
        child: const Icon(Icons.local_taxi, color: Colors.blue, size: 36),
      ));
    }

    // Marker pickup customer (xanh lá)
    markers.add(Marker(
      point: pickup,
      width: 40,
      height: 40,
      child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 40),
    ));

    // Marker đích đến (đỏ) - chỉ hiện khi xem lộ trình khách
    if (_showCustomerRoute) {
      markers.add(Marker(
        point: destination,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(
      widget.activeRide.pickupLatitude,
      widget.activeRide.pickupLongitude,
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── BẢN ĐỒ ──────────────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pickup,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'vn.khoaluan.ridenow.mobileapp.v1',
                ),
                // Layer Polyline
                PolylineLayer(
                  polylines: [
                    // Route driver → pickup (xanh dương)
                    if (_routePoints.isNotEmpty && !_showCustomerRoute)
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8,
                        color: const Color(0xFF223285),
                      ),
                    // Route customer (pickup → destination, màu cam)
                    if (_customerRoutePoints.isNotEmpty && _showCustomerRoute)
                      Polyline(
                        points: _customerRoutePoints,
                        strokeWidth: 8,
                        color: const Color(0xFFE65100),
                      ),
                  ],
                ),
                // Layer Marker
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          // ── HEADER ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Nút quay lại
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF223285),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showCustomerRoute
                                    ? Icons.flag
                                    : Icons.person_pin_circle,
                                color: _showCustomerRoute
                                    ? const Color(0xFFE65100)
                                    : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _showCustomerRoute
                                      ? 'Lộ trình: ${widget.activeRide.customerName}'
                                      : 'Đến đón: ${widget.activeRide.customerName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF223285),
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── LOADING INDICATOR ────────────────────────────────────────────
          if (_isLoadingRoute)
            const Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Đang tính đường...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── BOTTOM INFO PANEL ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Route info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        Icons.route,
                        _showCustomerRoute
                            ? (_customerDistance ?? '--')
                            : (_distance ?? '--'),
                        _showCustomerRoute
                            ? 'Quãng đường khách'
                            : 'Khoảng cách',
                        _showCustomerRoute
                            ? const Color(0xFFE65100)
                            : Colors.blue,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[200]),
                      _buildInfoChip(
                        Icons.timer,
                        _showCustomerRoute
                            ? (_customerDuration ?? '--')
                            : (_duration ?? '--'),
                        _showCustomerRoute ? 'Thời gian khách' : 'Thời gian',
                        _showCustomerRoute
                            ? const Color(0xFFE65100)
                            : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Địa chỉ pickup
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _showCustomerRoute
                                  ? 'ĐIỂM ĐÓN'
                                  : 'ĐIỂM ĐÓN KHÁCH',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              widget.activeRide.pickupAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Địa chỉ đích đến (chỉ hiện khi xem lộ trình khách)
                  if (_showCustomerRoute) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE65100),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ĐIỂM ĐẾN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                widget.activeRide.destinationAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Nút xem lộ trình khách hàng (pickup → destination)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingCustomerRoute
                          ? null
                          : () {
                              setState(
                                () => _showCustomerRoute = !_showCustomerRoute,
                              );
                              if (_showCustomerRoute &&
                                  _customerRoutePoints.isEmpty) {
                                _fetchCustomerRoute();
                              } else if (_showCustomerRoute &&
                                  _customerRoutePoints.isNotEmpty) {
                                // Fit camera theo route khách
                                if (_customerRoutePoints.length > 1) {
                                  try {
                                    final bounds = LatLngBounds.fromPoints(
                                      _customerRoutePoints,
                                    );
                                    _mapController.fitCamera(
                                      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                                    );
                                  } catch (_) {}
                                }
                              } else {
                                // Quay lại route driver → pickup
                                if (_routePoints.isNotEmpty) {
                                  try {
                                    final bounds = LatLngBounds.fromPoints(
                                      _routePoints,
                                    );
                                    _mapController.fitCamera(
                                      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                                    );
                                  } catch (_) {}
                                }
                              }
                            },
                      icon: _isLoadingCustomerRoute
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _showCustomerRoute
                                  ? Icons.navigation
                                  : Icons.map_outlined,
                              color: Colors.white,
                            ),
                      label: Text(
                        _showCustomerRoute
                            ? 'Xem đường đến khách'
                            : 'Đã nhận khách. Xem lộ trình khách',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showCustomerRoute
                            ? Colors.grey.shade600
                            : const Color(0xFFE65100),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── NÚT VỀ VỊ TRÍ HIỆN TẠI ─────────────────────────────────────
          Positioned(
            right: 15,
            bottom: 230,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_driverLocation != null) {
                  try {
                    _mapController.move(_driverLocation!, 17);
                  } catch (e) {
                    debugPrint('DriverNav: error centering map: $e');
                  }
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
