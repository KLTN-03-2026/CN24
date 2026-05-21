import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Bỏ FirebaseFirestore vì _firestoreService đã lo phần này
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Future<UserModel?> registerWithEmailAndPassword({
  //   required String name,
  //   required String email,
  //   required String password,
  //   required UserRole role,
  // }) async {
  //   try {
  //     final UserCredential userCredential = await _auth
  //         .createUserWithEmailAndPassword(
  //           email: email.trim(),
  //           password: password, // không trim password
  //         );
  //
  //     final User? user = userCredential.user;
  //     if (user == null) {
  //       throw 'Không thể khởi tạo phiên làm việc với Firebase Auth.';
  //     }
  //
  //     try {
  //       await user
  //           .updateDisplayName(name.trim())
  //           .timeout(
  //             const Duration(seconds: 10),
  //             onTimeout: () =>
  //                 throw 'Lỗi mạng khi cập nhật tên người dùng (Timeout)',
  //           );
  //     } catch (e) {
  //       debugPrint('[AuthService] Lỗi updateDisplayName: $e');
  //       // Tiếp tục chạy vì displayName không quá quan trọng
  //     }
  //
  //     final userModel = UserModel(
  //       id: user.uid,
  //       name: name.trim(),
  //       email: user.email ?? email.trim(),
  //       role: role,
  //       rating: 0,
  //       totalTrips: 0,
  //       createdAt: DateTime.now(),
  //     );
  //
  //     debugPrint(
  //       '[AuthService] Attempting to create user document via FirestoreService for UID: ${user.uid}',
  //     );
  //     try {
  //       await _firestoreService.createUser(userModel);
  //       debugPrint(
  //         '[AuthService] Successfully created user document via FirestoreService.',
  //       );
  //     } catch (e) {
  //       debugPrint('[AuthService] Error creating user document: $e');
  //       throw 'Lỗi khi lưu dữ liệu vào Firestore: $e';
  //     }
  //
  //     return userModel;
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'email-already-in-use') {
  //       throw 'Email đã được sử dụng.';
  //     }
  //     if (e.code == 'invalid-email') {
  //       throw 'Email không hợp lệ.';
  //     }
  //     if (e.code == 'weak-password') {
  //       throw 'Mật khẩu quá yếu.';
  //     }
  //     throw e.message ?? 'Đăng ký thất bại.';
  //   } on FirebaseException catch (e) {
  //     throw 'Lỗi Firestore: ${e.code} - ${e.message}';
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    UserCredential? userCredential;

    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Không thể khởi tạo phiên làm việc với Firebase Auth.');
      }

      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('[AuthService] updateDisplayName error: $e');
      }

      final userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        role: role,
        // rating: 0,
        // totalTrips: 0,
        isOnline: role == UserRole.driver ? false : null,
        isAvailable: role == UserRole.driver ? false : null,
        createdAt: DateTime.now(),
        isBlocked: false,
        status: 'Hoạt động',
      );

      debugPrint('[AuthService] Creating Firestore user for uid=${user.uid}');
      await _firestoreService.createUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthService] FirebaseAuthException: ${e.code} - ${e.message}',
      );

      if (e.code == 'email-already-in-use') {
        throw 'Email đã được sử dụng.';
      }
      if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ.';
      }
      if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu.';
      }
      throw e.message ?? 'Đăng ký thất bại.';
    } on FirebaseException catch (e) {
      debugPrint('[AuthService] FirebaseException: ${e.code} - ${e.message}');

      // rollback auth user nếu firestore fail
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete().catchError((_) {});
      }

      throw 'Lỗi Firestore: ${e.code} - ${e.message}';
    } catch (e) {
      debugPrint('[AuthService] Unknown register error: $e');

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete().catchError((_) {});
      }

      rethrow;
    }
  }

  Future<UserModel?> fetchUserModel(String uid) async {
    try {
      final userModel = await _firestoreService.getUser(uid);
      return userModel;
    } on Exception catch (e) {
      if (e.toString().contains('User not found')) {
        return null;
      }
      throw 'Không thể tải thông tin người dùng: ${e.toString()}';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định khi lấy dữ liệu người dùng: $e';
    }
  }

  // Future<UserModel> signInWithEmailAndPassword(
  //   String email,
  //   String password,
  // ) async {
  //   try {
  //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //       email: email.trim(),
  //       password: password.trim(),
  //     );
  //
  //     UserModel? userModel = await fetchUserModel(userCredential.user!.uid);
  //     if (userModel == null) {
  //       throw 'Không tìm thấy thông tin người dùng trong hệ thống (Firestore).';
  //     }
  //     return userModel;
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') throw 'Email không tồn tại.';
  //     if (e.code == 'wrong-password') throw 'Mật khẩu không chính xác.';
  //     if (e.code == 'invalid-email') throw 'Email không hợp lệ.';
  //     throw e.message ?? 'Đăng nhập thất bại.';
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw 'Không thể lấy thông tin người dùng từ Firebase Auth.';
      }

      UserModel? userModel = await fetchUserModel(firebaseUser.uid);

      if (userModel == null) {
        debugPrint(
          '[AuthService] Firestore user missing. Recreating profile...',
        );

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
      if (e.code == 'user-not-found' || 
          e.code == 'wrong-password' || 
          e.code == 'invalid-credential') {
        throw 'Sai email hoặc mật khẩu.';
      }
      if (e.code == 'invalid-email') throw 'Email không hợp lệ.';
      throw e.message ?? 'Đăng nhập thất bại.';
    }
  }

  Future<void> updateUserModel(UserModel userModel) async {
    await _firestoreService.updateUser(userModel);
  }

  Stream<UserModel?> watchUserModel(String uid) {
    return _firestoreService.watchUser(uid);
  }

  Future<void> logOut() async {
    await _auth.signOut();
  }
}
