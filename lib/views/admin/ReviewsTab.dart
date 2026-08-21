import 'package:flutter/material.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';

class ReviewsTab extends StatelessWidget {

  final ReviewController reviewCtrl;
  const ReviewsTab({required this.reviewCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final flagged = reviewCtrl.flaggedReviews.toList();

      if (flagged.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 64, color: AppColors.success),
              SizedBox(height: 16),
              Text('No flagged reviews!'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: flagged.length,
        itemBuilder: (_, i) {
          final review = flagged[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          review.flagReason ?? 'Flagged by AI detector',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(review.studentName[0].toUpperCase()),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.studentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text('Rating: ${review.rating}/5',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => reviewCtrl.approveReview(review.id),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => reviewCtrl.deleteReview(review.id),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

