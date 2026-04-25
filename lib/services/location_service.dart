import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/driver_location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Lấy vị trí hiện tại một lần
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Bắt đầu cập nhật vị trí driver lên Firestore
  Future<void> startDriverLocationUpdates(String driverId) async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật sau mỗi 10m
    );

    // Lấy vị trí ngay lập tức một lần đầu tiên
    try {
      Position initialPosition = await getCurrentPosition();
      await _updateDriverLocationInFirestore(driverId, initialPosition);
    } catch (e) {
      debugPrint('[LocationService] Cannot get initial position: $e');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updateDriverLocationInFirestore(driverId, position);
    });
  }

  // Dừng cập nhật
  void stopDriverLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> updateDriverStatus(String driverId, {bool? isOnline, bool? isAvailable}) async {
    try {
      final Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isOnline != null) data['isOnline'] = isOnline;
      if (isAvailable != null) data['isAvailable'] = isAvailable;

      await _firestore
          .collection('driver_locations')
          .doc(driverId)
          .set(data, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout updating driver status in driver_locations'),
          );
    } catch (e) {
      debugPrint('[LocationService] Status Update Error: $e');
      rethrow;
    }
  }

  Future<void> _updateDriverLocationInFirestore(String driverId, Position position) async {
    try {
      // Sử dụng set với merge: true để chỉ cập nhật các trường này mà không ghi đè isOnline/isAvailable
      await _firestore
          .collection('driver_locations')
          .doc(driverId)
          .set({
            'driverId': driverId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[LocationService] Update Error: $e');
    }
  }

  // Stream vị trí của một tài xế cụ thể (cho Customer theo dõi)
  Stream<DriverLocationModel> getDriverLocationStream(String driverId) {
    return _firestore
        .collection('driver_locations')
        .doc(driverId)
        .snapshots()
        .map((doc) => DriverLocationModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}));
  }
}
