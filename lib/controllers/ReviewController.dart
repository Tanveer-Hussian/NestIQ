import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/services/ReviewService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:get/get.dart';


class ReviewController extends GetxController {

  final ReviewService _reviewService = Get.find<ReviewService>();
  final HostelService _hostelService = Get.find<HostelService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ReviewModel> hostelReviews = <ReviewModel>[].obs;
  final RxList<ReviewModel> flaggedReviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;

  // ────────────────────────────────────────────────────────────────────────────
  // FR-6.1: Student submits a review
  // FR-6.3: AI-based suspicious review detection (simple heuristic here)
  // ────────────────────────────────────────────────────────────────────────────
  Future<bool> submitReview({
    required String hostelId,
    required double rating,
    required String comment,
  }) async {
    try {
      isLoading.value = true;

      final student = _authController.currentUser.value!;

      // Check if student has already reviewed
      final alreadyReviewed =
          await _reviewService.hasReviewed(student.uid, hostelId);
      if (alreadyReviewed) {
        Get.snackbar('Already Reviewed', 'You have already reviewed this hostel.');
        return false;
      }

      // ── FR-6.3: Simple fake review detection heuristic ──────────────────
      // In production, replace this with a TensorFlow Lite or Scikit-learn model
      final isSuspicious = _detectFakeReview(comment, rating);

      final review = ReviewModel(
        id: '',
        hostelId: hostelId,
        studentId: student.uid,
        studentName: student.name,
        studentImage: student.profileImage,
        rating: rating,
        comment: comment,
        isFlagged: isSuspicious,
        flagReason: isSuspicious ? 'Auto-flagged by AI detector' : null,
        createdAt: DateTime.now(),
      );

      await _reviewService.addReview(review);

      // Update hostel's average rating
      await _hostelService.updateHostelRating(hostelId, rating);

      Get.snackbar('Review Submitted', 'Thank you for your feedback!');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Could not submit review.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-6.3: Heuristic fake review detection.
  // Returns true if the review looks suspicious.
  // In production, call a TFLite or Scikit-learn model here.
  // ────────────────────────────────────────────────────────────────────────────
  bool _detectFakeReview(String comment, double rating) {
    // Rule 1: Extremely short comment with extreme rating
    if (comment.trim().length < 10 && (rating >= 5.0 || rating <= 1.0)) {
      return true;
    }

    // Rule 2: All capital letters (shouting/spam indicator)
    if (comment == comment.toUpperCase() && comment.length > 20) {
      return true;
    }

    // Rule 3: Repeated characters (e.g., "greaaaaat!!!")
    final repeatedChars = RegExp(r'(.)\1{4,}');
    if (repeatedChars.hasMatch(comment)) return true;

    return false;
  }

  void loadHostelReviews(String hostelId) {
    _reviewService
        .getHostelReviewsStream(hostelId)
        .listen((reviews) => hostelReviews.value = reviews);
  }

  void loadFlaggedReviews() {
    _reviewService
        .getFlaggedReviewsStream()
        .listen((reviews) => flaggedReviews.value = reviews);
  }

    // Delete a review (admin action)
  Future<void> deleteReview(String reviewId) async {
    await _reviewService.deleteReview(reviewId);
    Get.snackbar('Deleted', 'Review removed.');
  }

  // Approve a previously flagged review (mark as legitimate)
  Future<void> approveReview(String reviewId) async {
    await _reviewService.approveReview(reviewId);
    Get.snackbar('Approved', 'Review approved as legitimate.');
  }

}
