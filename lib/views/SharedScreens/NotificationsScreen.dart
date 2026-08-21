// lib/views/shared/profile_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-2.1: User views and updates their profile.
// Used by all roles (student, owner, admin).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';



// FR-9.x: Displays in-app notifications for all roles.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read
          TextButton(
            onPressed: ctrl.markAllAsRead,
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Obx(() {
        final notifications = ctrl.notifications;

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64, color: AppColors.divider),
                SizedBox(height: 16),
                Text('No notifications yet.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (_, i) {
            final n = notifications[i];
            return Dismissible(
              key: Key(n.id),
              // Swipe right to mark as read
              onDismissed: (_) => ctrl.markAsRead(n.id),
              background: Container(
                color: AppColors.primary,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              child: ListTile(
                // Unread notifications have a colored left border
                tileColor: n.isRead ? null : AppColors.primary.withOpacity(0.05),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _typeColor(n.type).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_typeIcon(n.type),
                      color: _typeColor(n.type), size: 20),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight:
                        n.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(n.body),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timeAgo(n.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    if (!n.isRead) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => ctrl.markAsRead(n.id),
              ),
            );
          },
        );
      }),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking': return AppColors.primary;
      case 'complaint': return AppColors.warning;
      case 'review': return Colors.amber;
      default: return AppColors.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking': return Icons.book_outlined;
      case 'complaint': return Icons.report_outlined;
      case 'review': return Icons.star_outline;
      default: return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
