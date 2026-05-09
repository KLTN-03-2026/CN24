import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../models/vehicle_profile_model.dart';
import '../services/storage_service.dart';
import '../services/vehicle_profile_service.dart';

/// Controller quản lý hồ sơ xe của tài xế
class VehicleProfileController extends GetxController {
  final VehicleProfileService _profileService = VehicleProfileService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final AuthController _authController = Get.find<AuthController>();

  // State
  final Rx<DriverVehicleProfile?> profile = Rx<DriverVehicleProfile?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxMap<String, bool> uploadingImages = <String, bool>{}.obs;

  // Editing state — cho mỗi section
  final RxBool isEditingDriverInfo = false.obs;
  final RxBool isEditingVehicleInfo = false.obs;
  final RxBool isEditingDocuments = false.obs;
  final RxBool isEditingLicenseInfo = false.obs;

  // Form data (editable copies)
  // Driver Info
  final RxString fullName = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString avatar = ''.obs;
  final RxString driverLicenseNumber = ''.obs;
  final RxString driverLicenseExpiry = ''.obs;
  final RxString driverLicensePhoto = ''.obs;
  final RxString nationalId = ''.obs;

  // Vehicle Info
  final RxString licensePlate = ''.obs;
  final RxString vehicleType = 'Car'.obs;
  final RxString brand = ''.obs;
  final RxString model = ''.obs;
  final RxString color = ''.obs;
  final RxString year = ''.obs;
  final RxString seatCount = ''.obs;
  final RxString vehiclePhoto = ''.obs;
  final RxString platePhoto = ''.obs;

  // Documents
  final RxString registrationNumber = ''.obs;
  final RxString registrationExpiry = ''.obs;
  final RxString insuranceNumber = ''.obs;
  final RxString insuranceExpiry = ''.obs;
  final RxString registrationPhoto = ''.obs;
  final RxString insurancePhoto = ''.obs;

  String get driverId => _authController.userModel?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  /// Tải hồ sơ xe từ Firestore
  Future<void> fetchProfile() async {
    if (driverId.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _profileService.getVehicleProfile(driverId);
      profile.value = result;

      if (result != null) {
        _populateFormFromProfile(result);
      } else {
        // Chưa có profile → pre-fill từ UserModel
        _populateFromUserModel();
      }
    } catch (e) {
      errorMessage.value = 'Không thể tải hồ sơ xe: $e';
      debugPrint('[VehicleProfileController] fetchProfile error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Điền form từ profile đang có
  void _populateFormFromProfile(DriverVehicleProfile p) {
    final v = p.currentVehicleInfo;
    final d = p.driverInfo;

    fullName.value = d.fullName ?? _authController.userModel?.name ?? '';
    phoneNumber.value = d.phoneNumber ?? _authController.userModel?.phone ?? '';
    avatar.value = d.avatar ?? '';
    driverLicenseNumber.value = d.driverLicenseNumber ?? '';
    driverLicenseExpiry.value = d.driverLicenseExpiry ?? '';
    driverLicensePhoto.value = d.driverLicensePhoto ?? '';
    nationalId.value = d.nationalId ?? '';

    licensePlate.value = v.licensePlate ?? '';
    vehicleType.value = v.vehicleType ?? 'Car';
    brand.value = v.brand ?? '';
    model.value = v.model ?? '';
    color.value = v.color ?? '';
    year.value = v.year?.toString() ?? '';
    seatCount.value = v.seatCount?.toString() ?? '';
    vehiclePhoto.value = v.vehiclePhoto ?? '';
    platePhoto.value = v.platePhoto ?? '';

    registrationNumber.value = v.registrationNumber ?? '';
    registrationExpiry.value = v.registrationExpiry ?? '';
    insuranceNumber.value = v.insuranceNumber ?? '';
    insuranceExpiry.value = v.insuranceExpiry ?? '';
    registrationPhoto.value = v.registrationPhoto ?? '';
    insurancePhoto.value = v.insurancePhoto ?? '';
  }

  /// Pre-fill từ UserModel khi chưa có vehicle profile
  void _populateFromUserModel() {
    final user = _authController.userModel;
    if (user == null) return;

    fullName.value = user.name;
    phoneNumber.value = user.phone ?? '';
    vehicleType.value = user.vehicleType ?? 'Car';
    licensePlate.value = user.vehiclePlate ?? '';
  }

  // ==================== VALIDATION ====================

  /// Validate toàn bộ form
  String? validateAll() {
    if (licensePlate.value.trim().isEmpty) {
      return 'Biển số xe không được để trống';
    }

    if (phoneNumber.value.trim().isNotEmpty &&
        !RegExp(r'^\+?[0-9\s]{9,15}$').hasMatch(phoneNumber.value.trim())) {
      return 'Số điện thoại không đúng định dạng';
    }

    if (year.value.trim().isNotEmpty) {
      final yearInt = int.tryParse(year.value.trim());
      if (yearInt == null || yearInt < 1900 || yearInt > DateTime.now().year + 1) {
        return 'Năm sản xuất không hợp lệ (1900 - ${DateTime.now().year + 1})';
      }
    }

    if (vehicleType.value == 'Car' && seatCount.value.trim().isNotEmpty) {
      final seats = int.tryParse(seatCount.value.trim());
      if (seats == null || seats < 1) {
        return 'Số chỗ ngồi phải >= 1';
      }
    }

    // Validate ngày hết hạn
    final expiryError = _validateExpiry(registrationExpiry.value, 'đăng ký xe');
    if (expiryError != null) return expiryError;

    final insuranceExpiryError = _validateExpiry(insuranceExpiry.value, 'bảo hiểm');
    if (insuranceExpiryError != null) return insuranceExpiryError;

    final licenseExpiryError = _validateExpiry(driverLicenseExpiry.value, 'GPLX');
    if (licenseExpiryError != null) return licenseExpiryError;

    return null;
  }

  /// Parse ngày từ định dạng dd/MM/YYYY → DateTime
  DateTime? _parseDdMmYyyy(String input) {
    final trimmed = input.trim();
    // Hỗ trợ cả dấu "/" và "-"
    final parts = trimmed.contains('/') ? trimmed.split('/') : trimmed.split('-');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final yearVal = int.tryParse(parts[2]);

    if (day == null || month == null || yearVal == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    try {
      return DateTime(yearVal, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Validate ngày hết hạn phải >= ngày hiện tại (format dd/MM/YYYY)
  String? _validateExpiry(String value, String fieldName) {
    if (value.trim().isEmpty) return null;
    final date = _parseDdMmYyyy(value);
    if (date == null) {
      return 'Ngày hết hạn $fieldName không đúng định dạng (dd/MM/YYYY)';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Ngày hết hạn $fieldName phải >= ngày hiện tại';
    }
    return null;
  }

  // ==================== SAVE ====================

  /// Lưu hồ sơ xe
  Future<void> saveProfile() async {
    // Validate
    final error = validateAll();
    if (error != null) {
      errorMessage.value = error;
      Get.snackbar('Lỗi', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSaving.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final vehicleInfo = VehicleInfo(
        licensePlate: licensePlate.value.trim(),
        vehicleType: vehicleType.value,
        brand: brand.value.trim().isNotEmpty ? brand.value.trim() : null,
        model: model.value.trim().isNotEmpty ? model.value.trim() : null,
        color: color.value.trim().isNotEmpty ? color.value.trim() : null,
        year: year.value.trim().isNotEmpty ? int.tryParse(year.value.trim()) : null,
        seatCount: vehicleType.value == 'Car' && seatCount.value.trim().isNotEmpty
            ? int.tryParse(seatCount.value.trim())
            : null,
        vehiclePhoto: vehiclePhoto.value.isNotEmpty ? vehiclePhoto.value : null,
        platePhoto: platePhoto.value.isNotEmpty ? platePhoto.value : null,
        registrationNumber: registrationNumber.value.trim().isNotEmpty
            ? registrationNumber.value.trim()
            : null,
        registrationExpiry: registrationExpiry.value.trim().isNotEmpty
            ? registrationExpiry.value.trim()
            : null,
        insuranceNumber: insuranceNumber.value.trim().isNotEmpty
            ? insuranceNumber.value.trim()
            : null,
        insuranceExpiry: insuranceExpiry.value.trim().isNotEmpty
            ? insuranceExpiry.value.trim()
            : null,
        registrationPhoto: registrationPhoto.value.isNotEmpty
            ? registrationPhoto.value
            : null,
        insurancePhoto: insurancePhoto.value.isNotEmpty
            ? insurancePhoto.value
            : null,
      );

      final driverInfo = DriverProfileInfo(
        fullName: fullName.value.trim().isNotEmpty ? fullName.value.trim() : null,
        phoneNumber: phoneNumber.value.trim().isNotEmpty ? phoneNumber.value.trim() : null,
        avatar: avatar.value.isNotEmpty ? avatar.value : null,
        driverLicenseNumber: driverLicenseNumber.value.trim().isNotEmpty
            ? driverLicenseNumber.value.trim()
            : null,
        driverLicenseExpiry: driverLicenseExpiry.value.trim().isNotEmpty
            ? driverLicenseExpiry.value.trim()
            : null,
        driverLicensePhoto: driverLicensePhoto.value.isNotEmpty
            ? driverLicensePhoto.value
            : null,
        nationalId: nationalId.value.trim().isNotEmpty
            ? nationalId.value.trim()
            : null,
      );

      if (profile.value == null) {
        // Tạo mới profile
        final newProfile = DriverVehicleProfile(
          driverId: driverId,
          status: ProfileStatus.pending_review,
          currentVehicleInfo: vehicleInfo,
          driverInfo: driverInfo,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await _profileService.createVehicleProfile(newProfile);
        profile.value = newProfile;
      } else {
        // Cập nhật profile — kiểm tra sensitive changes
        final sensitiveChanges = VehicleProfileService.detectSensitiveChanges(
          current: profile.value!.currentVehicleInfo,
          updated: vehicleInfo,
          currentDriver: profile.value!.driverInfo,
          updatedDriver: driverInfo,
        );

        final hasSensitive = sensitiveChanges != null;

        await _profileService.updateVehicleProfile(
          driverId: driverId,
          updatedVehicleInfo: vehicleInfo,
          updatedDriverInfo: driverInfo,
          hasSensitiveChanges: hasSensitive,
          sensitiveChangesMap: sensitiveChanges,
        );

        // Reload profile
        await fetchProfile();
      }

      // Tắt tất cả editing mode
      isEditingDriverInfo.value = false;
      isEditingVehicleInfo.value = false;
      isEditingDocuments.value = false;
      isEditingLicenseInfo.value = false;

      successMessage.value = 'Lưu thông tin thành công!';
      Get.snackbar(
        'Thành công',
        profile.value?.status == ProfileStatus.pending_review
            ? 'Thông tin đã được lưu và đang chờ duyệt'
            : 'Cập nhật thông tin thành công',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      errorMessage.value = 'Lỗi khi lưu: $e';
      Get.snackbar('Lỗi', 'Không thể lưu thông tin: $e',
          snackPosition: SnackPosition.BOTTOM);
      debugPrint('[VehicleProfileController] saveProfile error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ==================== IMAGE UPLOAD ====================

  /// Chọn và upload ảnh
  /// [imageType] — key của ảnh (vehiclePhoto, platePhoto, etc.)
  Future<void> pickAndUploadImage(String imageType) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (picked == null) return;

      // Set loading state cho ảnh này
      uploadingImages[imageType] = true;

      final File file = File(picked.path);
      final String url = await _storageService.uploadDriverImage(
        driverId: driverId,
        imageFile: file,
        imageType: imageType,
      );

      // Gán URL vào reactive field tương ứng
      _setImageUrl(imageType, url);
      uploadingImages[imageType] = false;

      debugPrint('[VehicleProfileController] Upload $imageType thành công: $url');
    } catch (e) {
      uploadingImages[imageType] = false;
      Get.snackbar('Lỗi', 'Không thể upload ảnh: $e');
      debugPrint('[VehicleProfileController] pickAndUploadImage error: $e');
    }
  }

  /// Chụp ảnh từ camera
  Future<void> takeAndUploadPhoto(String imageType) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (picked == null) return;

      uploadingImages[imageType] = true;

      final File file = File(picked.path);
      final String url = await _storageService.uploadDriverImage(
        driverId: driverId,
        imageFile: file,
        imageType: imageType,
      );

      _setImageUrl(imageType, url);
      uploadingImages[imageType] = false;
    } catch (e) {
      uploadingImages[imageType] = false;
      Get.snackbar('Lỗi', 'Không thể chụp ảnh: $e');
    }
  }

  /// Gán URL ảnh vào reactive field tương ứng
  void _setImageUrl(String imageType, String url) {
    switch (imageType) {
      case 'vehiclePhoto':
        vehiclePhoto.value = url;
        break;
      case 'platePhoto':
        platePhoto.value = url;
        break;
      case 'registrationPhoto':
        registrationPhoto.value = url;
        break;
      case 'insurancePhoto':
        insurancePhoto.value = url;
        break;
      case 'driverLicensePhoto':
        driverLicensePhoto.value = url;
        break;
      case 'avatar':
        avatar.value = url;
        break;
    }
  }

  /// Lấy URL ảnh hiện tại theo imageType
  String getImageUrl(String imageType) {
    switch (imageType) {
      case 'vehiclePhoto':
        return vehiclePhoto.value;
      case 'platePhoto':
        return platePhoto.value;
      case 'registrationPhoto':
        return registrationPhoto.value;
      case 'insurancePhoto':
        return insurancePhoto.value;
      case 'driverLicensePhoto':
        return driverLicensePhoto.value;
      case 'avatar':
        return avatar.value;
      default:
        return '';
    }
  }

  /// Kiểm tra ảnh đang upload
  bool isUploadingImage(String imageType) {
    return uploadingImages[imageType] ?? false;
  }
}
