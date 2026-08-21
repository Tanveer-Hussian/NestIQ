// ─────────────────────────────────────────────────────────────────────────────
// FR-6.1: Student submits a rating and written review.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../shared Widgets/CustomTextField.dart';


class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  // Accept either a HostelModel or just a hostelId string
  late final String _hostelId;
  late final String _hostelName;

  final ReviewController _reviewCtrl = Get.find<ReviewController>();
  final _commentController = TextEditingController();
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    // Get.arguments can be a HostelModel or a plain hostelId string
    final arg = Get.arguments;
    if (arg is HostelModel) {
      _hostelId = arg.id;
      _hostelName = arg.name;
    } else {
      _hostelId = arg as String;
      _hostelName = 'Hostel'; // fallback if only ID passed
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      Get.snackbar('Required', 'Please select a star rating.');
      return;
    }
    if (_commentController.text.trim().length < 10) {
      Get.snackbar('Too Short', 'Please write at least 10 characters.');
      return;
    }

    final success = await _reviewCtrl.submitReview(
      hostelId: _hostelId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
    );

    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hostel name
            Text(
              _hostelName,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share your experience to help other students',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // ── Star Rating ────────────────────────────────────────────────
            const Text('Your Rating *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Center(
              child: RatingBar.builder(
                initialRating: _selectedRating,
                minRating: 1,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) =>
                    setState(() => _selectedRating = rating),
              ),
            ),

            // Rating label
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(_selectedRating),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Written Review ─────────────────────────────────────────────
            const Text('Your Review *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Describe your experience: facilities, cleanliness, management, etc.',
              ),
            ),
            const SizedBox(height: 24),

            // Note about AI moderation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reviews are moderated by our AI system to ensure quality.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ──────────────────────────────────────────────
            Obx(() => CustomButton(
                  text: 'Submit Review',
                  isLoading: _reviewCtrl.isLoading.value,
                  icon: Icons.star_outline,
                  onPressed: _submitReview,
                )),
          ],
        ),
      ),
    );
  }

  // Map rating number to descriptive label
  String _ratingLabel(double r) {
    if (r == 0) return 'Tap a star to rate';
    if (r <= 1) return '⭐ Poor';
    if (r <= 2) return '⭐⭐ Fair';
    if (r <= 3) return '⭐⭐⭐ Good';
    if (r <= 4) return '⭐⭐⭐⭐ Very Good';
    return '⭐⭐⭐⭐⭐ Excellent!';
  }
}

