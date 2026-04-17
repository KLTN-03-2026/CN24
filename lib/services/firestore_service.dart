// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';
//
// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> createUser(UserModel user) async {
//     try {
//       await _firestore
//           .collection('users')
//           .doc(user.id)
//           .set(user.toMap())
//           .timeout(
//             const Duration(seconds: 10),
//             onTimeout: () => throw Exception('Lỗi mạng hoặc Rules: Timeout khi ghi vào Firestore.'),
//           );
//     } catch (e) {
//       throw Exception('Failed to create user: ${e.toString()}');
//     }
//   }
//
//   Future<UserModel> getUser(String userId) async {
//     try {
//       DocumentSnapshot doc = await _firestore
//           .collection('users')
//           .doc(userId)
//           .get();
//       if (doc.exists) {
//         return UserModel.fromMap(doc.data() as Map<String, dynamic>);
//       } else {
//         throw Exception('User not found');
//       }
//     } catch (e) {
//       throw Exception('Failed to get user: ${e.toString()}');
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Future<void> createUser(UserModel user) async {
  //   try {
  //     final data = user.toMap();
  //     debugPrint('createUser data = $data');
  //
  //     await _firestore.collection('users').doc(user.id).set(data).timeout(
  //       const Duration(seconds: 5),
  //       onTimeout: () {
  //         debugPrint('[FirestoreService] Mạng bị treo (Timeout). Bỏ qua lưu Firestore để có thể vào app.');
  //       },
  //     );
  //
  //     debugPrint('createUser SUCCESS (or bypassed): users/${user.id}');
  //   } on FirebaseException catch (e, st) {
  //     debugPrint('FIRESTORE ERROR CODE: ${e.code}');
  //     debugPrint('FIRESTORE ERROR MESSAGE: ${e.message}');
  //     debugPrint('FIRESTORE STACK: $st');
  //     rethrow;
  //   } catch (e, st) {
  //     debugPrint('UNKNOWN createUser ERROR: $e');
  //     debugPrint('STACK: $st');
  //     rethrow;
  //   }
  // } vesion 1

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
              debugPrint(
                '🔥 [LỖI NGHIÊM TRỌNG] Quá hạn 15s không ghi được vào Firestore. LÝ DO CHÍNH:',
              );
              debugPrint(
                '1. Bạn CHƯA bấm "Create Database" (Tạo cơ sở dữ liệu) trong mục Firestore Database ở Firebase Console.',
              );
              debugPrint('2. Máy ảo của bạn bị rớt mạng. Hoặc sai Rules.');
              throw Exception(
                'Ghi Firestore bị timeout sau 15 giây. Vui lòng kiểm tra lại bạn đã tạo Firestore Database trên Firebase Console chưa!',
              );
            },
          );

      debugPrint('createUser SUCCESS: users/${user.id}');
    } on FirebaseException catch (e, st) {
      debugPrint('FIRESTORE ERROR CODE: ${e.code}');
      debugPrint('FIRESTORE ERROR MESSAGE: ${e.message}');
      debugPrint('FIRESTORE STACK: $st');
      rethrow;
    } catch (e, st) {
      debugPrint('UNKNOWN createUser ERROR: $e');
      debugPrint('STACK: $st');
      rethrow;
    }
  }

  Future<UserModel> getUser(String userId) async {
    try {
      DocumentSnapshot doc;
      try {
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint(
          '[FirestoreService] getUser timeout/hang, thử lấy từ cache...',
        );
        doc = await _firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.cache));
      }

      debugPrint('[FirestoreService] getUser exists=${doc.exists} for $userId');

      if (!doc.exists || doc.data() == null) {
        throw Exception('User not found');
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      debugPrint(
        '[FirestoreService] FirebaseException getUser: code=${e.code}, message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[FirestoreService] Unknown getUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Kết nối mạng chập chờn, cập nhật quá thời gian (Timeout).',
            ),
          );
      debugPrint('updateUser SUCCESS: users/${user.id}');
    } catch (e) {
      debugPrint('[FirestoreService] updateUser error: $e');
      rethrow;
    }
  }
}
