import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/ReviewModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Review left by a student after confirmed stay.
// Stored in Firestore: /reviews/{reviewId}
// ─────────────────────────────────────────────────────────────────────────────

class ReviewModel {
  final String id;
  final String hostelId;
  final String studentId;
  final String studentName;
  final String? studentImage;
  final double rating;        // 1.0 – 5.0
  final String comment;
  final bool isFlagged;       // AI or manual flag for suspicious review
  final String? flagReason;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.hostelId,
    required this.studentId,
    required this.studentName,
    this.studentImage,
    required this.rating,
    required this.comment,
    this.isFlagged = false,
    this.flagReason,
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

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      hostelId: map['hostelId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      studentImage: map['studentImage']?.toString(),
      rating: _parseDouble(map['rating']),
      comment: map['comment']?.toString() ?? '',
      isFlagged: map['isFlagged'] == true,
      flagReason: map['flagReason']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostelId': hostelId,
      'studentId': studentId,
      'studentName': studentName,
      'studentImage': studentImage,
      'rating': rating,
      'comment': comment,
      'isFlagged': isFlagged,
      'flagReason': flagReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

