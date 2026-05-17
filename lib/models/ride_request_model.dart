import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus {
  pending,
  searching_driver,
  driver_assigned,
  accepted,
  rejected,
  timeout,
  on_the_way,
  ongoing,
  completed,
  cancelled
}

class RideRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? driverId;
  final double? distanceInKm;
  final RideStatus status;
  final DateTime createdAt;
  final double? fare;
  final String? driverPhone;
  final String? driverName;
  final String? customerPhone;
  final String paymentMethod;

  RideRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.driverId,
    this.distanceInKm,
    this.status = RideStatus.pending,
    required this.createdAt,
    this.fare,
    this.driverPhone,
    this.driverName,
    this.customerPhone,
    this.paymentMethod = 'Tiền mặt',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'pickupAddress': pickupAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationAddress': destinationAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'driverId': driverId,
      'distanceInKm': distanceInKm,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'fare': fare,
      'driverPhone': driverPhone,
      'driverName': driverName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
    };
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    return RideRequestModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: map['destinationAddress'] ?? '',
      destinationLatitude: (map['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (map['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      driverId: map['driverId'],
      distanceInKm: (map['distanceInKm'] as num?)?.toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      fare: (map['fare'] as num?)?.toDouble(),
      driverPhone: map['driverPhone'],
      driverName: map['driverName'],
      customerPhone: map['customerPhone'],
      paymentMethod: map['paymentMethod'] ?? 'Tiền mặt',
    );
  }

  RideRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    String? driverId,
    double? distanceInKm,
    RideStatus? status,
    DateTime? createdAt,
    double? fare,
    String? driverPhone,
    String? driverName,
    String? customerPhone,
    String? paymentMethod,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      driverId: driverId ?? this.driverId,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fare: fare ?? this.fare,
      driverPhone: driverPhone ?? this.driverPhone,
      driverName: driverName ?? this.driverName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
