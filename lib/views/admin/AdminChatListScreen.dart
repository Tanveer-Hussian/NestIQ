// Admin Chat List: shows all active conversations with hostel owners
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatCtrl = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(() {
        final rooms = chatCtrl.adminChatRooms;

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No Conversations Yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Message a hostel owner from their\nlisting details page.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rooms.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72),
          itemBuilder: (ctx, i) {
            final room = rooms[i];
            return _ChatRoomTile(
              room: room,
              onTap: () => Get.toNamed(
                AppRoutes.chatConversation,
                arguments: {
                  'roomId': room.id,
                  'title': room.ownerName,
                },
              ),
            );
          },
        );
      }),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final VoidCallback onTap;
  const _ChatRoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = room.unreadCountByAdmin;
    final timeLabel = _formatTime(room.lastMessageTime);

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          room.ownerName.isNotEmpty
              ? room.ownerName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark),
        ),
      ),
      title: Text(
        room.ownerName,
        style: TextStyle(
            fontWeight:
                unread > 0 ? FontWeight.bold : FontWeight.w500,
            fontSize: 15),
      ),
      subtitle: Text(
        room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: unread > 0
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight:
                unread > 0 ? FontWeight.w600 : FontWeight.normal),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: unread > 0
                      ? AppColors.primary
                      : AppColors.textSecondary)),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
