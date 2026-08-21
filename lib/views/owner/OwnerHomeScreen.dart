
// lib/views/owner/owner_home_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Hostel owner's dashboard. Shows their listings with stats.
// FR-3.x, FR-5.2, FR-7.2
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/models/HostelModel.dart';


class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authCtrl = Get.find<AuthController>();
    final HostelController hostelCtrl = Get.find<HostelController>();
    final BookingController bookingCtrl = Get.put(BookingController());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
                  authCtrl.currentUser.value?.name ?? 'Owner',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                )),
            const Text('Owner Dashboard'),
          ],
        ),
        actions: [
          // Notification badge
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Get.toNamed(AppRoutes.notifications),
          ),
        ],
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: _OwnerBottomNav(),

      // ── FAB to add new hostel ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addHostel),
        icon: const Icon(Icons.add),
        label: const Text('Add Hostel'),
        backgroundColor: AppColors.primary,
      ),

      body: RefreshIndicator(
        onRefresh: () async => hostelCtrl.loadOwnerHostels(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Row ──────────────────────────────────────────────────
              Obx(() => Row(
                    children: [
                      _StatCard(
                        label: 'Total Listings',
                        value: '${hostelCtrl.ownerHostels.length}',
                        icon: Icons.home_work_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Pending Bookings',
                        value: '${bookingCtrl.pendingBookingsCount}',
                        icon: Icons.pending_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Approved',
                        value: '${hostelCtrl.ownerHostels.where((h) => h.status == "approved").length}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ],
                  )),
              const SizedBox(height: 24),

              // ── My Listings ────────────────────────────────────────────────
              Text('My Listings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              Obx(() {
                if (hostelCtrl.ownerHostels.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.home_work_outlined,
                              size: 64, color: AppColors.divider),
                          const SizedBox(height: 16),
                          const Text('No listings yet.'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.addHostel),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Hostel'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  // Disable inner scroll – parent handles it
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: hostelCtrl.ownerHostels.length,
                  itemBuilder: (_, i) {
                    return _OwnerHostelCard(
                      hostel: hostelCtrl.ownerHostels[i],
                      hostelCtrl: hostelCtrl,
                    );
                  },
                );
              }),

              // Spacer for FAB clearance
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card widget ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Owner's hostel management card ────────────────────────────────────────
class _OwnerHostelCard extends StatelessWidget {
  final HostelModel hostel;
  final HostelController hostelCtrl;

  const _OwnerHostelCard({required this.hostel, required this.hostelCtrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Hostel image thumbnail
          if (hostel.images.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                hostel.images[0],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.divider,
                  child: const Icon(Icons.home_work_outlined, size: 40),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(hostel.name,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    StatusChip(status: hostel.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${hostel.city} · PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hostel.availableRooms}/${hostel.totalRooms} rooms available',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),

                // Pending approval notice
                if (hostel.status == AppConstants.statusPending) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text(
                          'Awaiting admin approval',
                          style: TextStyle(fontSize: 12, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action buttons row
                Row(
                  children: [
                    // Edit button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.editHostel,
                          arguments: hostel,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                    // Toggle availability
                    IconButton(
                      onPressed: () => hostelCtrl.updateHostel(
                        hostel.id,
                        {'isAvailable': !hostel.isAvailable},
                      ),
                      icon: Icon(
                        hostel.isAvailable
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        color: hostel.isAvailable
                            ? AppColors.success
                            : AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${hostel.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              hostelCtrl.deleteHostel(hostel.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Owner bottom nav ───────────────────────────────────────────────────────
class _OwnerBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final RxInt idx = 0.obs;
    return Obx(() => BottomNavigationBar(
          currentIndex: idx.value,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (i) {
            idx.value = i;
            switch (i) {
              case 0: break;
              case 1: Get.toNamed(AppRoutes.ownerBookings); break;
              case 2: Get.toNamed(AppRoutes.ownerComplaints); break;
              case 3: Get.toNamed(AppRoutes.ownerChats); break;
              case 4: Get.toNamed(AppRoutes.profile); break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Listings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ));
  }
}

