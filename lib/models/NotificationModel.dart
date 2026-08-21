import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/NotificationModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// In-app notification record.
// Stored in Firestore: /notifications/{notificationId}
// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String userId;      // Recipient's UID
  final String title;
  final String body;
  final String type;        // 'booking' | 'complaint' | 'review' | 'system'
  final String? relatedId;  // ID of the related document (bookingId, etc.)
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
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

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'system',
      relatedId: map['relatedId']?.toString(),
      isRead: map['isRead'] == true,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}


