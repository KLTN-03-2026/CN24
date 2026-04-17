import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái duyệt hồ sơ xe
enum ProfileStatus { approved, pending_review, rejected }

/// Thông tin xe + giấy tờ xe
class VehicleInfo {
  final String? licensePlate;
  final String? vehicleType; // "Car" | "Bike"
  final String? brand;
  final String? model;
  final String? color;
  final int? year;
  final int? seatCount; // null nếu Bike
  final String? vehiclePhoto;
  final String? platePhoto;
  final String? registrationNumber;
  final String? registrationExpiry;
  final String? insuranceNumber;
  final String? insuranceExpiry;
  final String? registrationPhoto;
  final String? insurancePhoto;

  VehicleInfo({
    this.licensePlate,
    this.vehicleType,
    this.brand,
    this.model,
    this.color,
    this.year,
    this.seatCount,
    this.vehiclePhoto,
    this.platePhoto,
    this.registrationNumber,
    this.registrationExpiry,
    this.insuranceNumber,
    this.insuranceExpiry,
    this.registrationPhoto,
    this.insurancePhoto,
  });

  factory VehicleInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return VehicleInfo();
    return VehicleInfo(
      licensePlate: map['licensePlate'],
      vehicleType: map['vehicleType'],
      brand: map['brand'],
      model: map['model'],
      color: map['color'],
      year: map['year'],
      seatCount: map['seatCount'],
      vehiclePhoto: map['vehiclePhoto'],
      platePhoto: map['platePhoto'],
      registrationNumber: map['registrationNumber'],
      registrationExpiry: map['registrationExpiry'],
      insuranceNumber: map['insuranceNumber'],
      insuranceExpiry: map['insuranceExpiry'],
      registrationPhoto: map['registrationPhoto'],
      insurancePhoto: map['insurancePhoto'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (licensePlate != null) map['licensePlate'] = licensePlate;
    if (vehicleType != null) map['vehicleType'] = vehicleType;
    if (brand != null) map['brand'] = brand;
    if (model != null) map['model'] = model;
    if (color != null) map['color'] = color;
    if (year != null) map['year'] = year;
    if (seatCount != null) map['seatCount'] = seatCount;
    if (vehiclePhoto != null) map['vehiclePhoto'] = vehiclePhoto;
    if (platePhoto != null) map['platePhoto'] = platePhoto;
    if (registrationNumber != null) map['registrationNumber'] = registrationNumber;
    if (registrationExpiry != null) map['registrationExpiry'] = registrationExpiry;
    if (insuranceNumber != null) map['insuranceNumber'] = insuranceNumber;
    if (insuranceExpiry != null) map['insuranceExpiry'] = insuranceExpiry;
    if (registrationPhoto != null) map['registrationPhoto'] = registrationPhoto;
    if (insurancePhoto != null) map['insurancePhoto'] = insurancePhoto;
    return map;
  }

  VehicleInfo copyWith({
    String? licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    String? color,
    int? year,
    int? seatCount,
    String? vehiclePhoto,
    String? platePhoto,
    String? registrationNumber,
    String? registrationExpiry,
    String? insuranceNumber,
    String? insuranceExpiry,
    String? registrationPhoto,
    String? insurancePhoto,
  }) {
    return VehicleInfo(
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      year: year ?? this.year,
      seatCount: seatCount ?? this.seatCount,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
      platePhoto: platePhoto ?? this.platePhoto,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      registrationPhoto: registrationPhoto ?? this.registrationPhoto,
      insurancePhoto: insurancePhoto ?? this.insurancePhoto,
    );
  }
}

/// Thông tin tài xế liên quan đến xe
class DriverProfileInfo {
  final String? fullName;
  final String? phoneNumber;
  final String? avatar;
  final String? driverLicenseNumber;
  final String? driverLicenseExpiry;
  final String? driverLicensePhoto;
  final String? nationalId;

  DriverProfileInfo({
    this.fullName,
    this.phoneNumber,
    this.avatar,
    this.driverLicenseNumber,
    this.driverLicenseExpiry,
    this.driverLicensePhoto,
    this.nationalId,
  });

  factory DriverProfileInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DriverProfileInfo();
    return DriverProfileInfo(
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      avatar: map['avatar'],
      driverLicenseNumber: map['driverLicenseNumber'],
      driverLicenseExpiry: map['driverLicenseExpiry'],
      driverLicensePhoto: map['driverLicensePhoto'],
      nationalId: map['nationalId'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (avatar != null) map['avatar'] = avatar;
    if (driverLicenseNumber != null) map['driverLicenseNumber'] = driverLicenseNumber;
    if (driverLicenseExpiry != null) map['driverLicenseExpiry'] = driverLicenseExpiry;
    if (driverLicensePhoto != null) map['driverLicensePhoto'] = driverLicensePhoto;
    if (nationalId != null) map['nationalId'] = nationalId;
    return map;
  }

  DriverProfileInfo copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatar,
    String? driverLicenseNumber,
    String? driverLicenseExpiry,
    String? driverLicensePhoto,
    String? nationalId,
  }) {
    return DriverProfileInfo(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverLicenseExpiry: driverLicenseExpiry ?? this.driverLicenseExpiry,
      driverLicensePhoto: driverLicensePhoto ?? this.driverLicensePhoto,
      nationalId: nationalId ?? this.nationalId,
    );
  }
}

/// Model chính: Hồ sơ xe của tài xế
class DriverVehicleProfile {
  final String driverId;
  final ProfileStatus status;
  final String? rejectionReason;
  final VehicleInfo currentVehicleInfo;
  final DriverProfileInfo driverInfo;
  final Map<String, dynamic>? pendingVehicleUpdate;
  final DateTime updatedAt;
  final DateTime createdAt;

  DriverVehicleProfile({
    required this.driverId,
    this.status = ProfileStatus.approved,
    this.rejectionReason,
    required this.currentVehicleInfo,
    required this.driverInfo,
    this.pendingVehicleUpdate,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Parse Firestore Timestamp hoặc các dạng khác
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Parse ProfileStatus từ string
  static ProfileStatus _parseStatus(String? value) {
    switch (value) {
      case 'pending_review':
        return ProfileStatus.pending_review;
      case 'rejected':
        return ProfileStatus.rejected;
      case 'approved':
      default:
        return ProfileStatus.approved;
    }
  }

  factory DriverVehicleProfile.fromMap(Map<String, dynamic> map) {
    return DriverVehicleProfile(
      driverId: map['driverId'] ?? '',
      status: _parseStatus(map['status']),
      rejectionReason: map['rejectionReason'],
      currentVehicleInfo: VehicleInfo.fromMap(
        map['currentVehicleInfo'] as Map<String, dynamic>?,
      ),
      driverInfo: DriverProfileInfo.fromMap(
        map['driverInfo'] as Map<String, dynamic>?,
      ),
      pendingVehicleUpdate: map['pendingVehicleUpdate'] as Map<String, dynamic>?,
      updatedAt: _parseDateTime(map['updatedAt']),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'currentVehicleInfo': currentVehicleInfo.toMap(),
      'driverInfo': driverInfo.toMap(),
      'pendingVehicleUpdate': pendingVehicleUpdate,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DriverVehicleProfile copyWith({
    String? driverId,
    ProfileStatus? status,
    String? rejectionReason,
    VehicleInfo? currentVehicleInfo,
    DriverProfileInfo? driverInfo,
    Map<String, dynamic>? pendingVehicleUpdate,
    bool clearPending = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return DriverVehicleProfile(
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentVehicleInfo: currentVehicleInfo ?? this.currentVehicleInfo,
      driverInfo: driverInfo ?? this.driverInfo,
      pendingVehicleUpdate: clearPending ? null : (pendingVehicleUpdate ?? this.pendingVehicleUpdate),
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
