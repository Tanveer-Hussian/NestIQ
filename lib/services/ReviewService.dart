// ─────────────────────────────────────────────────────────────────────────────
// ReviewService
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';

class ReviewService extends GetxService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colReviews);
 
  // FR-6.1: Add review
  Future<String> addReview(ReviewModel review) async {
    final docRef = await _col.add(review.toMap());
    return docRef.id;
  }
 
  // Hostel reviews — where+where+orderBy needs index, so sort client-side
  Stream<List<ReviewModel>> getHostelReviewsStream(String hostelId) {
    return _col
        .where('hostelId', isEqualTo: hostelId)
        .where('isFlagged', isEqualTo: false)
        // NO .orderBy — sort client-side instead
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }
 
  // Flag a review
  Future<void> flagReview(String reviewId, String reason) async {
    await _col.doc(reviewId).update({
      'isFlagged': true,
      'flagReason': reason,
    });
  }
 
  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    await _col.doc(reviewId).delete();
  }

  // Approve a previously flagged review (mark as legit)
  Future<void> approveReview(String reviewId) async {
    await _col.doc(reviewId).update({
      'isFlagged': false,
      'flagReason': null,
    });
  }
 
  // Flagged reviews for admin — single where, no orderBy needed
  Stream<List<ReviewModel>> getFlaggedReviewsStream() {
    return _col
        .where('isFlagged', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }
 
  // Check duplicate review
  Future<bool> hasReviewed(String studentId, String hostelId) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('hostelId', isEqualTo: hostelId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
