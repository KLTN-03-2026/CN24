import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service upload/xóa ảnh lên Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload ảnh xe/giấy tờ lên Storage
  /// [driverId] — ID tài xế
  /// [imageFile] — File ảnh cần upload
  /// [imageType] — Loại ảnh (vehiclePhoto, platePhoto, registrationPhoto, etc.)
  /// Trả về download URL
  Future<String> uploadDriverImage({
    required String driverId,
    required File imageFile,
    required String imageType,
  }) async {
    try {
      final String fileName =
          '${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref =
          _storage.ref().child('driver_vehicles/$driverId/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[StorageService] Upload thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Upload lỗi: $e');
      rethrow;
    }
  }

  /// Upload ảnh đại diện người dùng
  Future<String> uploadUserAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('avatars/$userId/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[StorageService] Upload avatar thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Upload avatar lỗi: $e');
      rethrow;
    }
  }

  /// Xóa ảnh cũ theo URL (nếu cần thay thế)
  Future<void> deleteImageByUrl(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('[StorageService] Xóa ảnh cũ thành công: $url');
    } catch (e) {
      // Không throw lỗi nếu xóa thất bại — ảnh cũ có thể đã bị xóa
      debugPrint('[StorageService] Không thể xóa ảnh cũ: $e');
    }
  }
}
