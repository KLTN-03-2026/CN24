// import 'package:cloud_firestore/cloud_firestore.dart';
//
// enum UserRole { customer, driver }
//
// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String? phone;
//   final UserRole role;
//
//   final String? avatar;
//
//   // Driver only
//   final String? vehicleType;
//   final String? vehiclePlate;
//   final bool? isOnline;
//
//   // location
//   final double? latitude;
//   final double? longitude;
//
//   final double rating;
//   final int totalTrips;
//
//   final DateTime createdAt;
//
//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.phone,
//     required this.role,
//     this.avatar,
//     this.vehicleType,
//     this.vehiclePlate,
//     this.isOnline,
//     this.latitude,
//     this.longitude,
//     this.rating = 0,
//     this.totalTrips = 0,
//     required this.createdAt,
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'],
//       name: json['name'],
//       email: json['email'],
//       phone: json['phone'],
//       role: json['role'] == 'driver' ? UserRole.driver : UserRole.customer,
//       avatar: json['avatar'],
//       vehicleType: json['vehicleType'],
//       vehiclePlate: json['vehiclePlate'],
//       isOnline: json['isOnline'],
//       latitude: json['latitude'],
//       longitude: json['longitude'],
//       rating: (json['rating'] ?? 0).toDouble(),
//       totalTrips: json['totalTrips'] ?? 0,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       "id": id,
//       "name": name,
//       "email": email,
//       "phone": phone,
//       "role": role.name,
//       "avatar": avatar,
//       "vehicleType": vehicleType,
//       "vehiclePlate": vehiclePlate,
//       "isOnline": isOnline,
//       "latitude": latitude,
//       "longitude": longitude,
//       "rating": rating,
//       "totalTrips": totalTrips,
//       'createdAt': Timestamp.fromDate(createdAt),
//     };
//   }
//
//   static UserModel fromMap(Map<String, dynamic> map) {
//     // parse createdAt: Firestore trả về Timestamp, không phải int
//     DateTime parseCreatedAt(dynamic value) {
//       if (value is Timestamp) return value.toDate();
//       if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
//       if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
//       return DateTime.now();
//     }
//
//     return UserModel(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       phone: map['phone'],
//       role: map['role'] == 'driver' ? UserRole.driver : UserRole.customer,
//       avatar: map['avatar'],
//       // vehicleType: map['vehicleType'] ?? '',
//       // vehiclePlate: map['vehiclePlate'] ?? '',
//       vehicleType: map['vehicleType'],
//       vehiclePlate: map['vehiclePlate'],
//       // bản sửa
//       isOnline: map['isOnline'] ?? false,
//       // latitude: map['latitude'],
//       // longitude: map['longitude'],
//       latitude: (map['latitude'] as num?)?.toDouble(),
//       longitude: (map['longitude'] as num?)?.toDouble(),
//       // bản sửa
//       rating: (map['rating'] ?? 0).toDouble(),
//       totalTrips: map['totalTrips'] ?? 0,
//       createdAt: parseCreatedAt(map['createdAt']),
//     );
//   }
//
//   // factory UserModel.fromJson(Map<String, dynamic> json) {
//   //   DateTime parseCreatedAt(dynamic value) {
//   //     if (value is Timestamp) return value.toDate();
//   //     if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
//   //     if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
//   //     return DateTime.now();
//   //   }
//   //
//   //   return UserModel(
//   //     id: json['id'] ?? '',
//   //     name: json['name'] ?? '',
//   //     email: json['email'] ?? '',
//   //     phone: json['phone'],
//   //     role: json['role'] == 'driver' ? UserRole.driver : UserRole.customer,
//   //     avatar: json['avatar'],
//   //     vehicleType: json['vehicleType'],
//   //     vehiclePlate: json['vehiclePlate'],
//   //     isOnline: json['isOnline'],
//   //     latitude: (json['latitude'] as num?)?.toDouble(),
//   //     longitude: (json['longitude'] as num?)?.toDouble(),
//   //     rating: (json['rating'] as num?)?.toDouble() ?? 0,
//   //     totalTrips: json['totalTrips'] ?? 0,
//   //     createdAt: parseCreatedAt(json['createdAt']),
//   //   );
//   // }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, driver }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatar;

  final String? vehicleType;
  final String? vehiclePlate;
  final bool? isOnline;
  final bool? isAvailable;

  final double? latitude;
  final double? longitude;

  final double rating;
  final int totalTrips;
  final int ratingCount;
  final double earnings;
  final DateTime createdAt;
  final String? language;
  final String? theme;

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
    this.ratingCount = 0,
    this.earnings = 0,
    required this.createdAt,
    this.language,
    this.theme,
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
      ratingCount: json['ratingCount'] ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      createdAt: _parseCreatedAt(json['createdAt']),
      language: json['language'],
      theme: json['theme'],
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
      'ratingCount': ratingCount,
      'earnings': earnings,
      'createdAt': Timestamp.fromDate(createdAt),
      'language': language,
      'theme': theme,
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
      ratingCount: map['ratingCount'] ?? 0,
      earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
      createdAt: _parseCreatedAt(map['createdAt']),
      language: map['language'],
      theme: map['theme'],
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatar,
    String? vehicleType,
    String? vehiclePlate,
    bool? isOnline,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalTrips,
    int? ratingCount,
    double? earnings,
    DateTime? createdAt,
    String? language,
    String? theme,
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
      ratingCount: ratingCount ?? this.ratingCount,
      earnings: earnings ?? this.earnings,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}
