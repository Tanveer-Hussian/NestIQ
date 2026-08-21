import 'dart:async';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/NotificationModel.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:get/get.dart';


class NotificationController extends GetxController {

  final NotificationService _service = Get.find<NotificationService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<NotificationModel>>? _notificationsSub;

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe reactive to auth status changes
    ever(_authController.currentUser, (user) {
      _subscribeToNotifications(user?.uid);
    });
    _subscribeToNotifications(_authController.currentUser.value?.uid);
  }

  void _subscribeToNotifications(String? uid) {
    _notificationsSub?.cancel();
    if (uid == null) {
      notifications.clear();
      unreadCount.value = 0;
      return;
    }

    // Stream notifications and compute unread count
    _notificationsSub = _service.getUserNotificationsStream(uid).listen((list) {
      notifications.value = list;
      unreadCount.value = list.where((n) => !n.isRead).length;
    });
  }

  @override
  void onClose() {
    _notificationsSub?.cancel();
    super.onClose();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;
    await _service.markAllAsRead(uid);
  }
}
