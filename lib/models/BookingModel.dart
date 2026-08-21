import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/BookingModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Represents a booking/reservation request made by a student.
// Stored in Firestore: /bookings/{bookingId}
// ─────────────────────────────────────────────────────────────────────────────

class BookingModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String hostelId;
  final String hostelName;
  final String ownerId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalAmount;
  final String status; // 'pending' | 'confirmed' | 'rejected' | 'cancelled'
  final String? ownerNote; // Owner's response message
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.hostelId,
    required this.hostelName,
    required this.ownerId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    this.status = 'pending',
    this.ownerNote,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      studentEmail: map['studentEmail']?.toString() ?? '',
      hostelId: map['hostelId']?.toString() ?? '',
      hostelName: map['hostelName']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      checkInDate: _parseDateTime(map['checkInDate']),
      checkOutDate: _parseDateTime(map['checkOutDate']),
      totalAmount: _parseDouble(map['totalAmount']),
      status: map['status']?.toString() ?? 'pending',
      ownerNote: map['ownerNote']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'hostelId': hostelId,
      'hostelName': hostelName,
      'ownerId': ownerId,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'totalAmount': totalAmount,
      'status': status,
      'ownerNote': ownerNote,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

