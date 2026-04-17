import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicle_profile_model.dart';

/// Service giao tiếp Firestore cho DriverVehicleProfile
class VehicleProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tên collection trên Firestore
  static const String _collection = 'driver_vehicle_profiles';

  /// Các trường nhạy cảm — khi thay đổi phải chuyển sang pending_review
  static const List<String> sensitiveFields = [
    'licensePlate',
    'brand',
    'model',
    'vehicleType',
    'vehiclePhoto',
    'platePhoto',
    'registrationNumber',
    'registrationPhoto',
    'insuranceNumber',
    'insurancePhoto',
    'driverLicenseNumber',
    'driverLicensePhoto',
  ];

  /// Lấy hồ sơ xe của driver
  Future<DriverVehicleProfile?> getVehicleProfile(String driverId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(driverId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists || doc.data() == null) {
        debugPrint('[VehicleProfileService] Chưa có hồ sơ xe cho $driverId');
        return null;
      }

      return DriverVehicleProfile.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[VehicleProfileService] getVehicleProfile error: $e');
      rethrow;
    }
  }

  /// Tạo hồ sơ xe mới
  Future<void> createVehicleProfile(DriverVehicleProfile profile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(profile.driverId)
          .set(profile.toMap())
          .timeout(const Duration(seconds: 15));

      debugPrint('[VehicleProfileService] Tạo hồ sơ xe thành công: ${profile.driverId}');
    } catch (e) {
      debugPrint('[VehicleProfileService] createVehicleProfile error: $e');
      rethrow;
    }
  }

  /// Cập nhật hồ sơ xe
  /// [hasSensitiveChanges] — nếu true, lưu vào pendingVehicleUpdate thay vì ghi đè
  Future<void> updateVehicleProfile({
    required String driverId,
    required VehicleInfo updatedVehicleInfo,
    required DriverProfileInfo updatedDriverInfo,
    required bool hasSensitiveChanges,
    Map<String, dynamic>? sensitiveChangesMap,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (hasSensitiveChanges && sensitiveChangesMap != null) {
        // Có thay đổi nhạy cảm → lưu vào pending, chuyển trạng thái chờ duyệt
        updateData['pendingVehicleUpdate'] = sensitiveChangesMap;
        updateData['status'] = ProfileStatus.pending_review.name;

        // Vẫn cập nhật các thông tin KHÔNG nhạy cảm trực tiếp
        updateData['driverInfo'] = updatedDriverInfo.toMap();

        // Cập nhật các field không nhạy cảm của vehicle
        final nonSensitiveVehicle = <String, dynamic>{};
        final vehicleMap = updatedVehicleInfo.toMap();
        for (final entry in vehicleMap.entries) {
          if (!sensitiveFields.contains(entry.key)) {
            nonSensitiveVehicle[entry.key] = entry.value;
          }
        }
        // Merge non-sensitive fields vào current
        for (final entry in nonSensitiveVehicle.entries) {
          updateData['currentVehicleInfo.${entry.key}'] = entry.value;
        }
      } else {
        // Không có thay đổi nhạy cảm → ghi trực tiếp
        updateData['currentVehicleInfo'] = updatedVehicleInfo.toMap();
        updateData['driverInfo'] = updatedDriverInfo.toMap();
      }

      await _firestore
          .collection(_collection)
          .doc(driverId)
          .update(updateData)
          .timeout(const Duration(seconds: 10));

      debugPrint('[VehicleProfileService] updateVehicleProfile thành công: $driverId');
    } catch (e) {
      debugPrint('[VehicleProfileService] updateVehicleProfile error: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem các thay đổi có chứa field nhạy cảm không
  /// So sánh dữ liệu mới với dữ liệu hiện tại
  static Map<String, dynamic>? detectSensitiveChanges({
    required VehicleInfo current,
    required VehicleInfo updated,
    required DriverProfileInfo currentDriver,
    required DriverProfileInfo updatedDriver,
  }) {
    final changes = <String, dynamic>{};
    final currentMap = current.toMap();
    final updatedMap = updated.toMap();
    final currentDriverMap = currentDriver.toMap();
    final updatedDriverMap = updatedDriver.toMap();

    // So sánh vehicle fields nhạy cảm
    for (final field in sensitiveFields) {
      final oldVal = currentMap[field];
      final newVal = updatedMap[field];
      if (newVal != null && newVal != oldVal) {
        changes[field] = newVal;
      }
      // Cũng check driver-related sensitive fields
      final oldDriverVal = currentDriverMap[field];
      final newDriverVal = updatedDriverMap[field];
      if (newDriverVal != null && newDriverVal != oldDriverVal) {
        changes[field] = newDriverVal;
      }
    }

    return changes.isEmpty ? null : changes;
  }
}
