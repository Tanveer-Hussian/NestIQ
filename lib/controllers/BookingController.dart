// ─────────────────────────────────────────────────────────────────────────────
// Manages booking state for students, owners, and admins.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';


class BookingController extends GetxController {
  
  final BookingService _bookingService = Get.find<BookingService>();
  final HostelService _hostelService = Get.find<HostelService>();
  final NotificationService _notificationService =Get.find<NotificationService>();
  final AuthController _authController = Get.find<AuthController>();

  // ── Observable state ──────────────────────────────────────────────────────
  final RxList<BookingModel> myBookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<BookingModel>>? _bookingsSub;

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe reactive to auth status changes
    ever(_authController.currentUser, (user) {
      _subscribeToBookings(user);
    });
    _subscribeToBookings(_authController.currentUser.value);
  }

  void _subscribeToBookings(dynamic user) {
    _bookingsSub?.cancel();
    if (user == null) {
      myBookings.clear();
      return;
    }
    if (_authController.isStudent) {
      _bookingsSub = _bookingService
          .getStudentBookingsStream(user.uid)
          .listen((bookings) => myBookings.value = bookings);
    } else if (_authController.isOwner) {
      _bookingsSub = _bookingService
          .getOwnerBookingsStream(user.uid)
          .listen((bookings) => myBookings.value = bookings);
    }
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    super.onClose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.1: Student requests a booking
  // ────────────────────────────────────────────────────────────────────────────
  Future<bool> requestBooking({
    required HostelModel hostel,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      isLoading.value = true;

      final student = _authController.currentUser.value!;

      // Check if student already has an active booking for this hostel
      final alreadyBooked = await _bookingService.hasActiveBooking(
        student.uid,
        hostel.id,
      );

      if (alreadyBooked) {
        Get.snackbar(
          'Already Booked',
          'You already have an active booking for this hostel.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Calculate total amount (check-out − check-in in months × rent)
      final months = checkOutDate.difference(checkInDate).inDays / 30;
      final totalAmount = hostel.rentPerMonth * months;

      final booking = BookingModel(
        id: '',
        studentId: student.uid,
        studentName: student.name,
        studentEmail: student.email,
        hostelId: hostel.id,
        hostelName: hostel.name,
        ownerId: hostel.ownerId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bookingService.createBooking(booking);

      // FR-9.2: Notify the hostel owner about new booking request
      await _notificationService.sendNotification(
        userId: hostel.ownerId,
        title: 'New Booking Request',
        body: '${student.name} requested to book ${hostel.name}.',
        type: 'booking',
      );

      Get.snackbar(
        'Request Sent',
        'Your booking request has been sent to the owner.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Booking failed. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.2: Owner accepts or rejects a booking
  // FR-5.3: Room availability is updated after confirmation
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> respondToBooking(
    BookingModel booking,
    String status, {
    String? note,
  }) async {
    try {
      isLoading.value = true;

      await _bookingService.updateBookingStatus(booking.id, status, ownerNote: note);

      // FR-5.3: If confirmed, decrement available rooms
      if (status == AppConstants.bookingConfirmed) {
        await _hostelService.decrementAvailableRooms(booking.hostelId);
      }

      // FR-9: Update ranking stats — every response counts as a booking decision
      await _hostelService.updateHostelStats(
        booking.hostelId,
        totalBookingsDelta: 1,
        confirmedBookingsDelta:
            status == AppConstants.bookingConfirmed ? 1 : 0,
      );

      // FR-9.1: Notify the student of the decision
      final statusMsg = status == AppConstants.bookingConfirmed
          ? 'confirmed ✅'
          : 'rejected ❌';
      await _notificationService.sendNotification(
        userId: booking.studentId,
        title: 'Booking $statusMsg',
        body: 'Your booking for ${booking.hostelName} has been $statusMsg.',
        type: 'booking',
        relatedId: booking.id,
      );

      Get.snackbar('Done', 'Booking $statusMsg successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update booking.');
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.4: Student cancels a booking
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> cancelBooking(BookingModel booking) async {
    try {
      await _bookingService.updateBookingStatus(
        booking.id,
        AppConstants.bookingCancelled,
      );

      // If booking was confirmed, restore available room count
      if (booking.status == AppConstants.bookingConfirmed) {
        await _hostelService.incrementAvailableRooms(booking.hostelId);
      }

      Get.snackbar('Cancelled', 'Booking cancelled successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Could not cancel booking.');
    }
  }

  // ── Get pending bookings count (for notification badge) ───────────────────
  int get pendingBookingsCount =>
      myBookings.where((b) => b.status == AppConstants.bookingPending).length;
}

