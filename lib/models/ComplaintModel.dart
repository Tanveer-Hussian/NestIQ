import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/ComplaintModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Service complaint submitted by a resident to the hostel owner.
// Stored in Firestore: /complaints/{complaintId}
// ─────────────────────────────────────────────────────────────────────────────

class ComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String hostelId;
  final String hostelName;
  final String ownerId;
  final String title;
  final String description;
  final String status; // 'pending' | 'in_progress' | 'resolved'
  final String? ownerResponse;
  final bool studentConfirmed; // true if student confirms resolution
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.hostelId,
    required this.hostelName,
    required this.ownerId,
    required this.title,
    required this.description,
    this.status = 'pending',
    this.ownerResponse,
    this.studentConfirmed = false,
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

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      hostelId: map['hostelId']?.toString() ?? '',
      hostelName: map['hostelName']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      ownerResponse: map['ownerResponse']?.toString(),
      studentConfirmed: map['studentConfirmed'] == true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'hostelId': hostelId,
      'hostelName': hostelName,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'status': status,
      'ownerResponse': ownerResponse,
      'studentConfirmed': studentConfirmed,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

