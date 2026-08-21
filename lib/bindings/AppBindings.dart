// lib/bindings/app_binding.dart
// ─────────────────────────────────────────────────────────────────────────────
// Registers all services and controllers as GetX singletons.
// UPDATED: StorageService replaced with CloudinaryService.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:get/get.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/services/CloudinaryService.dart';  // ← replaces StorageService
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/services/ReviewService.dart';
import 'package:fyp/services/ComplaintService.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/services/ChatService.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/controllers/ChatController.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {

    // ── Services ──────────────────────────────────────────────────────────────
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<HostelService>(HostelService(), permanent: true);

    // CloudinaryService replaces FirebaseStorageService
    // All image uploads now go to Cloudinary, URLs stored in Firestore
    Get.put<CloudinaryService>(CloudinaryService(), permanent: true);

    Get.put<BookingService>(BookingService(), permanent: true);
    Get.put<ReviewService>(ReviewService(), permanent: true);
    Get.put<ComplaintService>(ComplaintService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<ChatService>(ChatService(), permanent: true);

    // ── Controllers ───────────────────────────────────────────────────────────
    Get.put<AuthController>(AuthController(), permanent: true);

    Get.put<HostelController>(HostelController(), permanent: true);
    Get.put<BookingController>(BookingController(), permanent: true);
    Get.put<ReviewController>(ReviewController(), permanent: true);
    Get.put<ComplaintController>(ComplaintController(), permanent: true);
    Get.put<NotificationController>(NotificationController(), permanent: true);
    Get.put<ChatController>(ChatController(), permanent: true);
  }
}
