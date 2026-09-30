
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/utils/AppConstants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BookingService
// ─────────────────────────────────────────────────────────────────────────────
class BookingService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colBookings);

  // FR-5.1: Student submits a booking request
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _col.add(booking.toMap());
    return docRef.id;
  }

  // FR-5.2 / FR-5.3 / FR-10.2: Respond to booking status atomically via Firestore Transaction
  Future<void> respondToBookingWithTransaction(
    String bookingId,
    String hostelId,
    String status, {
    String? ownerNote,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _col.doc(bookingId);
      final hostelRef = _db.collection(AppConstants.colHostels).doc(hostelId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw Exception('Booking document does not exist.');
      }

      final hostelSnap = await transaction.get(hostelRef);

      // If confirming booking, verify room availability
      if (status == AppConstants.bookingConfirmed) {
        if (hostelSnap.exists) {
          final availableRooms = (hostelSnap.data()?['availableRooms'] ?? 0) as int;
          if (availableRooms <= 0) {
            throw Exception('Cannot confirm booking: No available rooms remaining.');
          }
        }
      }

      // 1. Update booking status
      final bookingUpdates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (ownerNote != null) bookingUpdates['ownerNote'] = ownerNote;
      transaction.update(bookingRef, bookingUpdates);

      // 2. Update hostel rooms & ranking stats atomically
      if (hostelSnap.exists) {
        final hostelUpdates = <String, dynamic>{
          'totalBookings': FieldValue.increment(1),
        };
        if (status == AppConstants.bookingConfirmed) {
          hostelUpdates['availableRooms'] = FieldValue.increment(-1);
          hostelUpdates['confirmedBookings'] = FieldValue.increment(1);
        }
        transaction.update(hostelRef, hostelUpdates);
      }
    });
  }

  // FR-5.4 / FR-10.2: Cancel booking atomically via Firestore Transaction
  Future<void> cancelBookingWithTransaction(
    String bookingId,
    String hostelId,
    String previousStatus,
  ) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _col.doc(bookingId);
      final hostelRef = _db.collection(AppConstants.colHostels).doc(hostelId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw Exception('Booking document does not exist.');
      }

      final hostelSnap = await transaction.get(hostelRef);

      // Update booking status
      transaction.update(bookingRef, {
        'status': AppConstants.bookingCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Restore available room if booking was confirmed
      if (previousStatus == AppConstants.bookingConfirmed && hostelSnap.exists) {
        transaction.update(hostelRef, {
          'availableRooms': FieldValue.increment(1),
        });
      }
    });
  }

  // Student booking history — sorted client-side to avoid composite index
  Stream<List<BookingModel>> getStudentBookingsStream(String studentId) {
    return _col
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Owner booking requests — sorted client-side
  Stream<List<BookingModel>> getOwnerBookingsStream(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // All bookings admin view — sort client-side
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _col
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Check for existing active booking
  Future<bool> hasActiveBooking(String studentId, String hostelId) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('hostelId', isEqualTo: hostelId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}


