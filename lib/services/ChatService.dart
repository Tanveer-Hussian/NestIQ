import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/models/MessageModel.dart';
import 'package:get/get.dart';

class ChatService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chatsCol => _db.collection('chats');

  // Deterministic room ID between admin and owner
  String getRoomId(String ownerId) => 'admin_$ownerId';

  // Get or create a chat room document
  Future<ChatRoomModel> getOrCreateChatRoom({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    final roomId = getRoomId(ownerId);
    final docRef = _chatsCol.doc(roomId);
    final snap = await docRef.get();

    if (snap.exists) {
      return ChatRoomModel.fromMap(snap.data()!, snap.id);
    } else {
      final room = ChatRoomModel(
        id: roomId,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        lastMessage: 'Conversation started',
        lastMessageTime: DateTime.now(),
        unreadCountByAdmin: 0,
        unreadCountByOwner: 0,
      );
      await docRef.set(room.toMap());
      return room;
    }
  }

  // Stream active conversations for admin (ordered by last message time)
  Stream<List<ChatRoomModel>> getAdminChatRoomsStream() {
    return _chatsCol
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream active conversation for a specific owner
  Stream<ChatRoomModel?> getOwnerChatRoomStream(String ownerId) {
    final roomId = getRoomId(ownerId);
    return _chatsCol.doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ChatRoomModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Stream messages in a chat room (ordered by createdAt ascending)
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _chatsCol
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required bool isAdminSender,
  }) async {
    final batch = _db.batch();

    // 1. Add message document
    final messageDocRef = _chatsCol.doc(roomId).collection('messages').doc();
    final message = MessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: DateTime.now(),
    );
    batch.set(messageDocRef, message.toMap());

    // 2. Update room summary
    final roomDocRef = _chatsCol.doc(roomId);
    final Map<String, dynamic> roomUpdate = {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };

    if (isAdminSender) {
      roomUpdate['unreadCountByOwner'] = FieldValue.increment(1);
    } else {
      roomUpdate['unreadCountByAdmin'] = FieldValue.increment(1);
    }

    batch.update(roomDocRef, roomUpdate);
    await batch.commit();
  }

  // Clear unread counts for admin
  Future<void> clearUnreadForAdmin(String roomId) async {
    await _chatsCol.doc(roomId).update({'unreadCountByAdmin': 0});
  }

  // Clear unread counts for owner
  Future<void> clearUnreadForOwner(String roomId) async {
    await _chatsCol.doc(roomId).update({'unreadCountByOwner': 0});
  }
}
