# Luồng Đăng nhập & Đăng ký - Ứng dụng RideNow

> Tài liệu mô tả chi tiết luồng chạy chức năng Login và Sign Up, bao gồm tất cả các file code liên quan.

---

## Mục lục
1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Sơ đồ luồng chạy](#2-sơ-đồ-luồng-chạy)
3. [File 1: UserModel (Model dữ liệu)](#3-file-1-usermodel)
4. [File 2: FirestoreService (Tương tác Firestore)](#4-file-2-firestoreservice)
5. [File 3: AuthService (Xác thực Firebase)](#5-file-3-authservice)
6. [File 4: AuthController (Điều phối logic)](#6-file-4-authcontroller)
7. [File 5: LoginView (Giao diện đăng nhập)](#7-file-5-loginview)
8. [File 6: RegisterView (Giao diện đăng ký)](#8-file-6-registerview)
9. [Cấu trúc Firestore Database](#9-cấu-trúc-firestore-database)

---

## 1. Tổng quan kiến trúc

Ứng dụng sử dụng mô hình **MVC + Service Layer** với GetX làm State Management:

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌──────────────┐
│   View (UI)  │ ──▶ │  AuthController  │ ──▶ │   AuthService    │ ──▶ │ Firebase Auth│
│ Login/Register│    │  (GetX Controller│     │ (Business Logic) │     │ + Firestore  │
└──────────────┘     └──────────────────┘     └──────────────────┘     └──────────────┘
                                                       │
                                                       ▼
                                              ┌──────────────────┐
                                              │ FirestoreService │
                                              │ (CRUD users)     │
                                              └──────────────────┘
```

**Các thư viện sử dụng:**
- `firebase_auth` — Xác thực người dùng
- `cloud_firestore` — Lưu trữ thông tin người dùng
- `get` (GetX) — Quản lý trạng thái (State Management) và điều hướng (Navigation)

---

## 2. Sơ đồ luồng chạy

### 2.1. Luồng Đăng ký (Sign Up)

```
Người dùng nhấn "Create Account"
       │
       ▼
RegisterView._signup()
  ├── Validate form (tên, email, password, confirm password)
  └── Gọi AuthController.registerWithEmailAndPassword(name, email, password, role)
       │
       ├── 1. _isAuthenticating = true (khóa listener)
       ├── 2. _isLoading = true (hiện loading trên UI)
       │
       └── Gọi AuthService.registerWithEmailAndPassword(...)
            │
            ├── 3. Firebase Auth: createUserWithEmailAndPassword()
            │      → Tạo tài khoản xác thực, trả về uid
            │
            ├── 4. Firebase Auth: updateDisplayName(name)
            │      → Cập nhật tên hiển thị (không bắt buộc thành công)
            │
            ├── 5. Tạo UserModel object với đầy đủ thông tin
            │
            ├── 6. FirestoreService.createUser(userModel)
            │      → Ghi document vào collection "users" với ID = uid
            │
            └── return UserModel
       │
       ├── 7. _userModel.value = userModel (cập nhật state)
       ├── 8. Get.snackbar("Thành công", ...)
       ├── 9. Get.offAllNamed(AppRoutes.main) → Vào màn hình chính
       │
       └── finally:
            ├── _isAuthenticating = false (mở khóa listener)
            └── _isLoading = false (tắt loading)
```

**Xử lý lỗi đặc biệt:** Nếu bước 6 (ghi Firestore) thất bại, code sẽ **rollback** bằng cách xóa user Auth vừa tạo (`currentUser.delete()`) để đảm bảo đồng bộ.

### 2.2. Luồng Đăng nhập (Login)

```
Người dùng nhấn "Log In"
       │
       ▼
LoginView: Kiểm tra email & password không rỗng
  └── Gọi AuthController.signInWithEmailAndPassword(email, password)
       │
       ├── 1. _isAuthenticating = true
       ├── 2. _isLoading = true
       │
       └── Gọi AuthService.signInWithEmailAndPassword(...)
            │
            ├── 3. Firebase Auth: signInWithEmailAndPassword()
            │      → Xác thực tài khoản, trả về uid
            │
            ├── 4. AuthService.fetchUserModel(uid)
            │      → FirestoreService.getUser(uid)
            │      → Đọc document từ collection "users"
            │      → Trả về UserModel (bao gồm role: customer/driver)
            │
            ├── 5. Nếu UserModel = null (mất data Firestore):
            │      → Tạo lại profile mặc định với role = customer
            │      → Ghi lại vào Firestore
            │
            └── return UserModel
       │
       ├── 6. _userModel.value = userModel
       ├── 7. debugPrint: In ra role (CUSTOMER/DRIVER)
       ├── 8. Get.snackbar("Thành công", ...)
       ├── 9. Get.offAllNamed(AppRoutes.main)
       │
       └── finally:
            ├── _isAuthenticating = false
            └── _isLoading = false
```

### 2.3. Luồng Auto-Login (Auth State Listener)

```
App khởi chạy
       │
       ▼
AuthController.onInit()
  ├── Bind stream: authStateChanges → _user
  └── ever(_user, _handleAuthStateChange)
       │
       ▼
_handleAuthStateChange(User? user)
  │
  ├── Nếu _isAuthenticating == true → RETURN (bỏ qua, chờ login/register xong)
  │
  ├── Nếu user == null (chưa đăng nhập / đã đăng xuất):
  │   └── Chuyển hướng → LoginView
  │
  └── Nếu user != null (đã đăng nhập trước đó):
      ├── fetchUserModel(uid) → Lấy thông tin từ Firestore
      └── Nếu đang ở Splash/Login/Register → Chuyển hướng → MainView
```

---

## 3. File 1: UserModel

**Đường dẫn:** `lib/models/user_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, driver }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatar;

  // Chỉ dành cho Driver
  final String? vehicleType;
  final String? vehiclePlate;
  final bool? isOnline;
  final bool? isAvailable;

  // Vị trí GPS (Driver)
  final double? latitude;
  final double? longitude;

  final double rating;
  final int totalTrips;
  final double earnings;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.vehicleType,
    this.vehiclePlate,
    this.isOnline,
    this.isAvailable,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.totalTrips = 0,
    this.earnings = 0,
    required this.createdAt,
  });

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] == 'driver' ? UserRole.driver : UserRole.customer,
      avatar: json['avatar'],
      vehicleType: json['vehicleType'],
      vehiclePlate: json['vehiclePlate'],
      isOnline: json['isOnline'],
      isAvailable: json['isAvailable'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalTrips: json['totalTrips'] ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'rating': rating,
      'totalTrips': totalTrips,
      'earnings': earnings,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (phone != null) map['phone'] = phone;
    if (avatar != null) map['avatar'] = avatar;
    if (vehicleType != null) map['vehicleType'] = vehicleType;
    if (vehiclePlate != null) map['vehiclePlate'] = vehiclePlate;
    if (isOnline != null) map['isOnline'] = isOnline;
    if (isAvailable != null) map['isAvailable'] = isAvailable;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;

    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: map['role'] == 'driver' ? UserRole.driver : UserRole.customer,
      avatar: map['avatar'],
      vehicleType: map['vehicleType'],
      vehiclePlate: map['vehiclePlate'],
      isOnline: map['isOnline'],
      isAvailable: map['isAvailable'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      totalTrips: map['totalTrips'] ?? 0,
      earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? id, String? name, String? email, String? phone,
    UserRole? role, String? avatar, String? vehicleType,
    String? vehiclePlate, bool? isOnline, bool? isAvailable,
    double? latitude, double? longitude, double? rating,
    int? totalTrips, double? earnings, DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      earnings: earnings ?? this.earnings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

## 4. File 2: FirestoreService

**Đường dẫn:** `lib/services/firestore_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo document user mới trong collection "users"
  Future<void> createUser(UserModel user) async {
    try {
      final data = user.toMap();
      debugPrint('createUser data = $data');

      await _firestore
          .collection('users')
          .doc(user.id)
          .set(data)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Ghi Firestore bị timeout sau 15 giây.');
            },
          );

      debugPrint('createUser SUCCESS: users/${user.id}');
    } on FirebaseException catch (e, st) {
      debugPrint('FIRESTORE ERROR: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Đọc thông tin user từ Firestore theo uid
  Future<UserModel> getUser(String userId) async {
    try {
      DocumentSnapshot doc;
      try {
        // Thử lấy từ server trước (timeout 5s)
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // Nếu timeout, thử lấy từ cache local
        debugPrint('[FirestoreService] getUser timeout, thử lấy từ cache...');
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.cache));
      }

      if (!doc.exists || doc.data() == null) {
        throw Exception('User not found');
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[FirestoreService] getUser error: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin user (merge để không ghi đè toàn bộ)
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      debugPrint('updateUser SUCCESS: users/${user.id}');
    } catch (e) {
      debugPrint('[FirestoreService] updateUser error: $e');
      rethrow;
    }
  }
}
```

---

## 5. File 3: AuthService

**Đường dẫn:** `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// === ĐĂNG KÝ ===
  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    UserCredential? userCredential;

    try {
      // Bước 1: Tạo tài khoản trên Firebase Authentication
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Không thể khởi tạo phiên làm việc với Firebase Auth.');
      }

      // Bước 2: Cập nhật tên hiển thị
      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('[AuthService] updateDisplayName error: $e');
      }

      // Bước 3: Tạo UserModel
      final userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        role: role,
        isOnline: role == UserRole.driver ? false : null,
        isAvailable: role == UserRole.driver ? false : null,
        createdAt: DateTime.now(),
      );

      // Bước 4: Lưu vào Firestore collection "users"
      debugPrint('[AuthService] Creating Firestore user for uid=${user.uid}');
      await _firestoreService.createUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw 'Email đã được sử dụng.';
      if (e.code == 'invalid-email') throw 'Email không hợp lệ.';
      if (e.code == 'weak-password') throw 'Mật khẩu quá yếu.';
      throw e.message ?? 'Đăng ký thất bại.';
    } on FirebaseException catch (e) {
      // Rollback: Xóa user Auth nếu ghi Firestore thất bại
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete().catchError((_) {});
      }
      throw 'Lỗi Firestore: ${e.code} - ${e.message}';
    } catch (e) {
      // Rollback cho mọi lỗi khác
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete().catchError((_) {});
      }
      rethrow;
    }
  }

  /// === ĐĂNG NHẬP ===
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Bước 1: Xác thực với Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw 'Không thể lấy thông tin người dùng từ Firebase Auth.';
      }

      // Bước 2: Lấy thông tin chi tiết từ Firestore (bao gồm Role)
      UserModel? userModel = await fetchUserModel(firebaseUser.uid);

      // Bước 3: Nếu mất dữ liệu Firestore, tạo lại profile mặc định
      if (userModel == null) {
        debugPrint('[AuthService] Firestore user missing. Recreating...');
        final recreatedUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? email.trim(),
          role: UserRole.customer,
          rating: 0,
          totalTrips: 0,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(recreatedUser);
        return recreatedUser;
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') throw 'Email không tồn tại.';
      if (e.code == 'wrong-password') throw 'Mật khẩu không chính xác.';
      if (e.code == 'invalid-email') throw 'Email không hợp lệ.';
      throw e.message ?? 'Đăng nhập thất bại.';
    }
  }

  /// Lấy UserModel từ Firestore theo uid
  Future<UserModel?> fetchUserModel(String uid) async {
    try {
      final userModel = await _firestoreService.getUser(uid);
      return userModel;
    } on Exception catch (e) {
      if (e.toString().contains('User not found')) return null;
      throw 'Không thể tải thông tin người dùng: ${e.toString()}';
    }
  }

  /// Cập nhật thông tin user
  Future<void> updateUserModel(UserModel userModel) async {
    await _firestoreService.updateUser(userModel);
  }

  /// Đăng xuất
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
```

---

## 6. File 4: AuthController

**Đường dẫn:** `lib/controllers/auth_controller.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isInitialized = false.obs;

  // Flag ngăn auth state change navigate khi đang xác thực
  bool _isAuthenticating = false;

  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value != null;

  @override
  void onInit() {
    super.onInit();
    // Lắng nghe trạng thái đăng nhập từ Firebase Auth
    _user.bindStream(_authService.authStateChanges);
    ever<User?>(_user, _handleAuthStateChange);
  }

  /// Xử lý tự động khi trạng thái Auth thay đổi (mở app, login, logout)
  Future<void> _handleAuthStateChange(User? user) async {
    if (!_isInitialized.value) _isInitialized.value = true;

    // Nếu đang trong quá trình login/register → bỏ qua (tránh redirect sớm)
    if (_isAuthenticating) return;

    if (user == null) {
      // Chưa đăng nhập hoặc đã đăng xuất → về Login
      _userModel.value = null;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != AppRoutes.login) {
          Get.offAllNamed(AppRoutes.login);
        }
      });
      return;
    }

    // Đã đăng nhập → lấy thông tin từ Firestore
    try {
      _isLoading.value = true;
      if (_userModel.value == null || _userModel.value!.id != user.uid) {
        final model = await _authService.fetchUserModel(user.uid);
        _userModel.value = model;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }

    // Chỉ redirect sang Main nếu đang ở màn hình auth
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final currentRoute = Get.currentRoute;
      if (currentRoute == AppRoutes.login ||
          currentRoute == AppRoutes.register ||
          currentRoute == AppRoutes.splash ||
          currentRoute == AppRoutes.onboarding) {
        Get.offAllNamed(AppRoutes.main);
      }
    });
  }

  /// === HÀM ĐĂNG NHẬP ===
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      _isAuthenticating = true; // Khóa listener

      final userModel = await _authService.signInWithEmailAndPassword(email, password);
      _userModel.value = userModel;

      debugPrint('[LOGIN SUCCESS] Role: ${userModel.role.name.toUpperCase()}');
      Get.snackbar('Thành công', 'Đăng nhập thành công với quyền ${userModel.role.name}!');

      await Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed To Login: ${e.toString()}');
    } finally {
      _isAuthenticating = false; // Mở khóa
      _isLoading.value = false;
    }
  }

  /// === HÀM ĐĂNG KÝ ===
  Future<void> registerWithEmailAndPassword(
    String name, String email, String password, String role,
  ) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      _isAuthenticating = true;

      UserRole userRole = UserRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => UserRole.customer,
      );

      final userModel = await _authService.registerWithEmailAndPassword(
        name: name, email: email, password: password, role: userRole,
      );

      if (userModel == null) throw Exception('Registration failed.');

      _userModel.value = userModel;
      Get.snackbar('Thành công', 'Đăng ký thành công!');
      await Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isAuthenticating = false;
      _isLoading.value = false;
    }
  }

  /// === ĐĂNG XUẤT ===
  void logOut() async {
    await _authService.logOut();
    _userModel.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
```

---

## 7. File 5: LoginView

**Đường dẫn:** `lib/views/auth/login_view.dart`

```dart
class LoginView extends StatefulWidget { ... }

class _RideNowLoginScreenState extends State<LoginView> {
  final AuthController _authController = Get.find<AuthController>();
  final emailController = TextEditingController();
  final passController = TextEditingController();

  // Khi người dùng nhấn nút "Log In":
  // 1. Kiểm tra email và password không rỗng
  // 2. Gọi _authController.signInWithEmailAndPassword()
  // 3. UI tự động hiển thị loading spinner nhờ Obx(() => ...)

  // Nút chuyển sang trang Đăng ký:
  // Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterView()))
}
```

**Các thành phần UI chính:**
- TextField Email (với icon mail)
- TextField Password (với nút ẩn/hiện mật khẩu)
- Nút "Forgot password?" (chưa triển khai)
- Nút "Log In" (pill button, có loading indicator)
- Link "Don't have an account? Sign Up"
- Nút "Continue with Google" (chưa triển khai)

---

## 8. File 6: RegisterView

**Đường dẫn:** `lib/views/auth/register_view.dart`

```dart
class RegisterView extends StatefulWidget { ... }

class _RegisterScreenState extends State<RegisterView> {
  final AuthController _authController = Get.find<AuthController>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  String selectedRole = "customer"; // Mặc định là Customer

  void _signup() {
    if (_formKey.currentState!.validate()) {
      _authController.registerWithEmailAndPassword(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passController.text,
        selectedRole, // "customer" hoặc "driver"
      );
    }
  }
}
```

**Các thành phần UI chính:**
- TextField Tên (Full Name)
- TextField Email
- RadioButton chọn Role: Customer / Driver
- TextField Password (tối thiểu 6 ký tự)
- TextField Confirm Password (phải khớp với Password)
- Nút "Create Account" (có loading indicator)

---

## 9. Cấu trúc Firestore Database

### Collection: `users`

Mỗi document có ID = Firebase Auth UID.

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | string | Firebase Auth UID |
| `name` | string | Tên người dùng |
| `email` | string | Email đăng nhập |
| `phone` | string? | Số điện thoại (tùy chọn) |
| `role` | string | `"customer"` hoặc `"driver"` |
| `avatar` | string? | URL ảnh đại diện |
| `vehicleType` | string? | Loại xe (Driver only) |
| `vehiclePlate` | string? | Biển số xe (Driver only) |
| `isOnline` | bool? | Đang trực tuyến? (Driver only) |
| `isAvailable` | bool? | Sẵn sàng nhận cuốc? (Driver only) |
| `latitude` | double? | Vĩ độ GPS (Driver only) |
| `longitude` | double? | Kinh độ GPS (Driver only) |
| `rating` | double | Đánh giá trung bình (mặc định: 0) |
| `totalTrips` | int | Tổng số chuyến (mặc định: 0) |
| `earnings` | double | Tổng thu nhập (mặc định: 0) |
| `createdAt` | Timestamp | Ngày tạo tài khoản |

---

> **Ghi chú:** Tài liệu này được tạo tự động từ mã nguồn ứng dụng RideNow.
> Ngày tạo: 30/03/2026
