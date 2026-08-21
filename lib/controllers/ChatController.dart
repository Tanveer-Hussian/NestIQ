import 'dart:async';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/models/MessageModel.dart';
import 'package:fyp/services/ChatService.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ChatService _chatService = Get.find<ChatService>();
  final AuthController _authCtrl = Get.find<AuthController>();

  // ── Observables ────────────────────────────────────────────────────────────
  final RxList<ChatRoomModel> adminChatRooms = <ChatRoomModel>[].obs;
  final Rxn<ChatRoomModel> ownerChatRoom = Rxn<ChatRoomModel>();
  final RxList<MessageModel> activeRoomMessages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription<List<ChatRoomModel>>? _adminRoomsSub;
  StreamSubscription<ChatRoomModel?>? _ownerRoomSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;

  @override
  void onInit() {
    super.onInit();
    // Start listening based on user role
    ever(_authCtrl.currentUser, (user) {
      _cancelAllSubs();
      if (user != null) {
        if (user.role == 'admin') {
          _listenToAdminRooms();
        } else if (user.role == 'owner') {
          _listenToOwnerRoom(user.uid);
        }
      }
    });

    // Handle initial login state if already logged in
    final currentUser = _authCtrl.currentUser.value;
    if (currentUser != null) {
      if (currentUser.role == 'admin') {
        _listenToAdminRooms();
      } else if (currentUser.role == 'owner') {
        _listenToOwnerRoom(currentUser.uid);
      }
    }
  }

  @override
  void onClose() {
    _cancelAllSubs();
    super.onClose();
  }

  void _cancelAllSubs() {
    _adminRoomsSub?.cancel();
    _ownerRoomSub?.cancel();
    _messagesSub?.cancel();
    activeRoomMessages.clear();
  }

  // Listen to all chat rooms for admin
  void _listenToAdminRooms() {
    _adminRoomsSub?.cancel();
    _adminRoomsSub = _chatService.getAdminChatRoomsStream().listen((rooms) {
      adminChatRooms.value = rooms;
    });
  }

  // Listen to single chat room for owner
  void _listenToOwnerRoom(String ownerId) {
    _ownerRoomSub?.cancel();
    _ownerRoomSub = _chatService.getOwnerChatRoomStream(ownerId).listen((room) {
      ownerChatRoom.value = room;
    });
  }

  // Listen to messages in a specific room
  void listenToMessages(String roomId) {
    _messagesSub?.cancel();
    activeRoomMessages.clear();
    _messagesSub = _chatService.getMessagesStream(roomId).listen((msgs) {
      activeRoomMessages.value = msgs;
      // Mark as read when messages are actively viewed
      _clearUnread(roomId);
    });
  }

  // Stop listening to messages (when leaving the screen)
  void stopListeningToMessages() {
    _messagesSub?.cancel();
    activeRoomMessages.clear();
  }

  // Get or create room and navigate to it
  Future<String> startOrGetConversation({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    try {
      isLoading.value = true;
      final room = await _chatService.getOrCreateChatRoom(
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
      );
      return room.id;
    } finally {
      isLoading.value = false;
    }
  }

  // Send message
  Future<void> sendChatMessage(String roomId, String content) async {
    if (content.trim().isEmpty) return;

    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    final isAdmin = user.role == 'admin';

    await _chatService.sendMessage(
      roomId: roomId,
      senderId: user.uid,
      senderName: user.name,
      content: content.trim(),
      isAdminSender: isAdmin,
    );
  }

  // Clear unread counts helper
  void _clearUnread(String roomId) {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;

    if (user.role == 'admin') {
      _chatService.clearUnreadForAdmin(roomId);
    } else if (user.role == 'owner') {
      _chatService.clearUnreadForOwner(roomId);
    }
  }
}
