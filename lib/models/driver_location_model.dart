import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLocationModel {
  final String driverId;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final bool isAvailable;
  final DateTime updatedAt;

  DriverLocationModel({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.isOnline,
    required this.isAvailable,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DriverLocationModel.fromMap(Map<String, dynamic> map) {
    return DriverLocationModel(
      driverId: map['driverId'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      isOnline: map['isOnline'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
