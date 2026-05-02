import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String customerId;
  final String customerName;
  final String driverId;
  final String driverName;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double fare;
  final double distance;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? rating;
  final String? feedback;

  TripModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.fare,
    required this.distance,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.rating,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'driverId': driverId,
      'driverName': driverName,
      'pickupAddress': pickupAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationAddress': destinationAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'fare': fare,
      'distance': distance,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rating': rating,
      'feedback': feedback,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: map['destinationAddress'] ?? '',
      destinationLatitude: (map['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (map['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      fare: (map['fare'] as num?)?.toDouble() ?? 0.0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Tiền mặt',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      rating: (map['rating'] as num?)?.toDouble(),
      feedback: map['feedback'],
    );
  }
}
