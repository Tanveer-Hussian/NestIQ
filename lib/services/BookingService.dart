
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

  // FR-5.2 / FR-5.4: Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    String? ownerNote,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (ownerNote != null) updates['ownerNote'] = ownerNote;
    await _col.doc(bookingId).update(updates);
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


