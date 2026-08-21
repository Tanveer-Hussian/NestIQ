// ─────────────────────────────────────────────────────────────────────────────
// Card widget to display a hostel summary in the search/browse list.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/PlaceHolderImage.dart';

class HostelCard extends StatelessWidget {
  final dynamic hostel; // HostelModel
  final VoidCallback onTap;

  const HostelCard({super.key, required this.hostel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias, // rounded corners clip the image
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hostel Image ──────────────────────────────────────────────
            SizedBox(
              height: 160,
              width: double.infinity,
              child: hostel.images.isNotEmpty
                  ? Image.network(
                      hostel.images[0],
                      fit: BoxFit.cover,
                      // Show shimmer while loading
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(color: AppColors.divider);
                      },
                      errorBuilder: (ctx, err, stack) =>
                          PlaceholderImage(),
                    )
                  : PlaceholderImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name & Rating ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hostel.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating badge
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            hostel.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${hostel.totalReviews})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Location ────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hostel.city,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Rent & Gender ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Gender preference chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hostel.genderPreference,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Availability ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hostel.isAvailable
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 14,
                            color: hostel.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hostel.isAvailable
                                ? '${hostel.availableRooms} rooms available'
                                : 'No rooms available',
                            style: TextStyle(
                              fontSize: 12,
                              color: hostel.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      // ML Score
                      if (hostel.smartScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Score: ${hostel.smartScore!.toStringAsFixed(0)}/100',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
