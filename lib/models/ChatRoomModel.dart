import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCountByAdmin;
  final int unreadCountByOwner;

  ChatRoomModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCountByAdmin,
    required this.unreadCountByOwner,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? '',
      ownerEmail: map['ownerEmail']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageTime: _parseDateTime(map['lastMessageTime']),
      unreadCountByAdmin: map['unreadCountByAdmin'] is int ? map['unreadCountByAdmin'] : 0,
      unreadCountByOwner: map['unreadCountByOwner'] is int ? map['unreadCountByOwner'] : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCountByAdmin': unreadCountByAdmin,
      'unreadCountByOwner': unreadCountByOwner,
    };
  }
}
