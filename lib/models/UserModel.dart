import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;          // 'student' | 'owner' | 'admin'
  final String phone;
  final String? profileImage;
  final String? university;
  final String? cnicImageUrl;   // Front-side CNIC image URL (owners only)
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.profileImage,
    this.university,
    this.cnicImageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  // ── Firestore document → UserModel ─────────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      phone: map['phone']?.toString() ?? '',
      profileImage: map['profileImage']?.toString(),
      university: map['university']?.toString(),
      cnicImageUrl: map['cnicImageUrl']?.toString(),
      // Default isActive to true unless explicitly set to false, and always true for admin
      isActive: (map['role'] == 'admin') || (map['isActive'] != false),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  // ── UserModel → Firestore Map ──────────────────────────────────────────────
  // FIXED: Use FieldValue.serverTimestamp() for createdAt.
  // Raw Dart DateTime throws:
  //   "Invalid argument: Instance of 'DateTime'"
  // FieldValue.serverTimestamp() is the correct Firestore way to store time.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImage': profileImage,
      'university': university,
      'cnicImageUrl': cnicImageUrl,
      'isActive': isActive,
      // Always use server timestamp — never send raw DateTime to Firestore
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Returns a modified copy ────────────────────────────────────────────────
  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? university,
    String? cnicImageUrl,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      university: university ?? this.university,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
