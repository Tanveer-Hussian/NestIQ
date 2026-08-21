// ─────────────────────────────────────────────────────────────────────────────
// FR-4.3: Full hostel details – images, facilities, map, reviews.
// FR-5.1: Student can tap "Book Now" to submit a booking request.
// FR-4.4: OpenStreetMap integration to show hostel location.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';



class HostelDetailScreen extends StatefulWidget {
  const HostelDetailScreen({super.key});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  // Get hostel passed via Get.arguments
  late final HostelModel hostel = Get.arguments as HostelModel;

  final ReviewController reviewCtrl = Get.find<ReviewController>();
  final AuthController authCtrl = Get.find<AuthController>();
  final BookingController bookingCtrl = Get.find<BookingController>();
  final ComplaintController complaintCtrl = Get.find<ComplaintController>();

  // Track which image is currently shown in the carousel
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load reviews for this specific hostel
    reviewCtrl.loadHostelReviews(hostel.id);
    // Load complaints for this specific hostel
    complaintCtrl.loadHostelComplaints(hostel.id);
  }

  // ── Open Google Maps navigation to hostel ─────────────────────────────────
  Future<void> _openMapsNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hostel.latitude},${hostel.longitude}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image Gallery in SliverAppBar ────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hostel.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: hostel.images.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (ctx, i) => Image.network(
                        hostel.images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.divider,
                          child: const Icon(Icons.home_work_outlined,
                              size: 64, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.divider,
                      child: const Icon(Icons.home_work_outlined,
                          size: 64, color: AppColors.textSecondary),
                    ),
            ),
            // Image counter dots
            bottom: hostel.images.length > 1
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(20),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          hostel.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _currentImageIndex == i ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // ── Detail Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name & Rating Row ──────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hostel.name,
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${hostel.city} · ${hostel.address}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rating column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hostel.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hostel.totalReviews} reviews',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Info Chips ──────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hostel.smartScore != null)
                        _InfoChip(
                          icon: Icons.auto_graph_outlined,
                          label: 'Smart Score: ${hostel.smartScore!.toStringAsFixed(0)}/100',
                          color: Colors.amber.shade700,
                        ),
                      _InfoChip(
                        icon: Icons.hotel,
                        label: hostel.roomType,
                      ),
                      _InfoChip(
                        icon: Icons.people_outline,
                        label: hostel.genderPreference,
                      ),
                      _InfoChip(
                        icon: Icons.meeting_room_outlined,
                        label: '${hostel.availableRooms} rooms left',
                        color: hostel.availableRooms > 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      _InfoChip(
                        icon: Icons.bookmark_added_outlined,
                        label: '${hostel.totalBookings} Bookings',
                        color: AppColors.primary,
                      ),
                      _InfoChip(
                        icon: Icons.check_circle_outline,
                        label: '${(hostel.complaintResolutionRate * 100).toStringAsFixed(0)}% Resolution Rate',
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ───────────────────────────────────────────
                  _SectionTitle(title: 'About this Hostel'),
                  const SizedBox(height: 8),
                  Text(
                    hostel.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),

                  // ── Facilities ────────────────────────────────────────────
                  _SectionTitle(title: 'Facilities'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hostel.facilities
                        .map((f) => _FacilityChip(label: f))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Map Location Card ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'Google Maps Location'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${hostel.latitude.toStringAsFixed(4)}, ${hostel.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // flutter_map — OpenStreetMap (no API key needed)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(hostel.latitude, hostel.longitude),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.fyp',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(hostel.latitude, hostel.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openMapsNavigation,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Open & Navigate in Google Maps'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Complaints Section (Conditional Visibility) ─────────────
                  Obx(() {
                    bool canViewComplaints = false;
                    if (authCtrl.isAdmin) {
                      canViewComplaints = true;
                    } else if (authCtrl.isOwner && authCtrl.currentUser.value?.uid == hostel.ownerId) {
                      canViewComplaints = true;
                    } else if (authCtrl.isStudent) {
                      // Only students with a CONFIRMED booking can see & file complaints
                      canViewComplaints = bookingCtrl.myBookings.any(
                        (b) => b.hostelId == hostel.id &&
                               b.status == AppConstants.bookingConfirmed,
                      );
                    }

                    if (!canViewComplaints) return const SizedBox.shrink();

                    final complaints = complaintCtrl.hostelComplaints;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(title: 'Complaints'),
                            if (authCtrl.isStudent && canViewComplaints)
                              TextButton.icon(
                                onPressed: () => Get.toNamed(
                                  AppRoutes.submitComplaint,
                                  arguments: hostel,
                                ),
                                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                                label: const Text('Report Issue'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (complaints.isEmpty)
                          const Text(
                            'No complaints found for this hostel.',
                            style: TextStyle(color: AppColors.textSecondary),
                          )
                        else
                          Column(
                            children: complaints
                                .map((c) => _ComplaintTile(complaint: c))
                                .toList(),
                          ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),

                  // ── Reviews Section ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'Reviews'),
                      // Write review button (students only)
                      if (authCtrl.isStudent)
                        TextButton.icon(
                          onPressed: () => Get.toNamed(
                            AppRoutes.writeReview,
                            arguments: hostel,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Write Review'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reviews list
                  Obx(() {
                    final reviews = reviewCtrl.hostelReviews;
                    if (reviews.isEmpty) {
                      return const Text(
                        'No reviews yet. Be the first!',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                      children: reviews
                          .take(5) // show max 5 reviews on detail page
                          .map((r) => _ReviewTile(review: r))
                          .toList(),
                    );
                  }),

                  // Bottom padding for FAB clearance
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Book Now Button ────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rent display
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Rent',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Book now button
            Expanded(
              child: ElevatedButton(
                onPressed: hostel.isAvailable && hostel.availableRooms > 0
                    ? () => Get.toNamed(AppRoutes.bookingRequest, arguments: hostel)
                    : null,
                child: Text(
                  hostel.isAvailable && hostel.availableRooms > 0
                      ? 'Book Now'
                      : 'Not Available',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small info chip ────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Facility badge chip ────────────────────────────────────────────────────
class _FacilityChip extends StatelessWidget {
  final String label;
  const _FacilityChip({required this.label});

  // Map facility names to icons
  IconData _iconFor(String f) {
    switch (f) {
      case 'WiFi': return Icons.wifi;
      case 'Mess / Cafeteria': return Icons.restaurant_outlined;
      case 'Security Guard': return Icons.security;
      case 'CCTV': return Icons.videocam_outlined;
      case 'Generator': return Icons.electric_bolt_outlined;
      case 'Laundry': return Icons.local_laundry_service_outlined;
      case 'Parking': return Icons.local_parking;
      case 'Gym': return Icons.fitness_center_outlined;
      case 'Air Conditioning': return Icons.ac_unit;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Section title widget ───────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── Single review tile ─────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info + rating
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: review.studentImage != null
                    ? NetworkImage(review.studentImage!)
                    : null,
                child: review.studentImage == null
                    ? Text(
                        review.studentName[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryDark),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemSize: 14,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: Colors.amber),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(review.createdAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment),
        ],
      ),
    );
  }

  // Simple "time ago" helper
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).round()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

// ── Single complaint tile ──────────────────────────────────────────────────
class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final isResolved = complaint.status == 'resolved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'By ${complaint.studentName}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(complaint.description),
          if (complaint.ownerResponse != null && complaint.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Owner Response:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Text(complaint.ownerResponse!),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
