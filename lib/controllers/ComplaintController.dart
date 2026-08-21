import 'dart:async';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/services/ComplaintService.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:get/get.dart';

class ComplaintController extends GetxController {

  final ComplaintService _complaintService = Get.find<ComplaintService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final HostelService _hostelService = Get.find<HostelService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ComplaintModel> myComplaints = <ComplaintModel>[].obs;
  final RxList<ComplaintModel> allComplaints = <ComplaintModel>[].obs;
  final RxList<ComplaintModel> hostelComplaints = <ComplaintModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<ComplaintModel>>? _complaintsSub;
  StreamSubscription<List<ComplaintModel>>? _hostelComplaintsSub;

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe reactive to auth status changes
    ever(_authController.currentUser, (user) {
      _subscribeToComplaints(user);
    });
    _subscribeToComplaints(_authController.currentUser.value);
  }

  void _subscribeToComplaints(dynamic user) {
    _complaintsSub?.cancel();
    if (user == null) {
      myComplaints.clear();
      allComplaints.clear();
      return;
    }

    if (_authController.isStudent) {
      _complaintsSub = _complaintService
          .getStudentComplaintsStream(user.uid)
          .listen((c) => myComplaints.value = c);
    } else if (_authController.isOwner) {
      _complaintsSub = _complaintService
          .getOwnerComplaintsStream(user.uid)
          .listen((c) => myComplaints.value = c);
    } else if (_authController.isAdmin) {
      _complaintsSub = _complaintService
          .getAllComplaintsStream()
          .listen((c) => allComplaints.value = c);
    }
  }

  @override
  void onClose() {
    _complaintsSub?.cancel();
    _hostelComplaintsSub?.cancel();
    super.onClose();
  }

  // ── Load complaints for a specific hostel (e.g. for detail page) ──────────
  void loadHostelComplaints(String hostelId) {
    _hostelComplaintsSub?.cancel();
    _hostelComplaintsSub = _complaintService
        .getHostelComplaintsStream(hostelId)
        .listen((c) => hostelComplaints.value = c);
  }

  // ── FR-7.1: Student submits a complaint ───────────────────────────────────
  Future<bool> submitComplaint({
    required String hostelId,
    required String hostelName,
    required String ownerId,
    required String title,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      final student = _authController.currentUser.value!;

      final complaint = ComplaintModel(
        id: '',
        studentId: student.uid,
        studentName: student.name,
        hostelId: hostelId,
        hostelName: hostelName,
        ownerId: ownerId,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _complaintService.submitComplaint(complaint);

      // FR-9: Increment total complaints counter for ranking
      await _hostelService.updateHostelStats(
        hostelId,
        totalComplaintsDelta: 1,
      );

      // Notify owner of new complaint
      await _notificationService.sendNotification(
        userId: ownerId,
        title: 'New Complaint',
        body: '${student.name} submitted a complaint about $hostelName.',
        type: 'complaint',
      );

      Get.snackbar('Submitted', 'Your complaint has been submitted.');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Could not submit complaint.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── FR-7.4: Student confirms resolution status
  Future<void> confirmResolution(ComplaintModel complaint, bool confirmed) async {
    try {
      await _complaintService.confirmResolution(complaint.id, confirmed);
      // Notify owner about student confirmation
      await _notificationService.sendNotification(
        userId: complaint.ownerId,
        title: 'Resolution Confirmation',
        body: confirmed
            ? '${complaint.studentName} confirmed the issue is resolved.'
            : '${complaint.studentName} marked the issue as not resolved.',
        type: 'complaint',
        relatedId: complaint.id,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not confirm resolution.');
    }
  }

  // ── FR-7.2: Owner responds to complaint ───────────────────────────────────
  Future<void> respondToComplaint(
    ComplaintModel complaint,
    String response,
    String status,
  ) async {
    await _complaintService.respondToComplaint(complaint.id, response, status);

    // FR-9: If resolved, increment resolved complaints counter for ranking
    if (status == 'resolved') {
      final durationHours = DateTime.now().difference(complaint.createdAt).inHours;
      await _hostelService.updateHostelStats(
        complaint.hostelId,
        resolvedComplaintsDelta: 1,
        resolutionTimeHoursDelta: durationHours,
      );
    }

    // FR-9.3: Notify the student of the update
    await _notificationService.sendNotification(
      userId: complaint.studentId,
      title: 'Complaint Update',
      body: 'Your complaint about ${complaint.hostelName} is now: $status.',
      type: 'complaint',
      relatedId: complaint.id,
    );

    Get.snackbar('Updated', 'Response sent to student.');
  }
}

