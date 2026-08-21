// ─────────────────────────────────────────────────────────────────────────────
// Main home screen for students. Shows search bar, city filter, and hostel list.
// FR-4.1, FR-4.2, FR-4.3
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/HostelCard.dart';
import 'package:get/get.dart';


class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authCtrl = Get.find<AuthController>();
    final HostelController hostelCtrl = Get.find<HostelController>();
    final NotificationController notifCtrl = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with user's name
            Obx(() => Text(
                  'Hello, ${authCtrl.currentUser.value?.name.split(' ').first ?? 'Student'} 👋',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                )),
            const Text('Find Your Hostel'),
          ],
        ),
        actions: [
          // ── Notification bell with unread badge ──────────────────────────
          Obx(() {
            final count = notifCtrl.unreadCount.value;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBar: _StudentBottomNav(),
      body: Column(
        children: [
          // ── Search & Filter Header ─────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Search bar (navigates to search screen on tap)
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.hostelSearch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text(
                          'Search hostels by city...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── City Filter Chips ────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: Obx(() => ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // "All" chip to clear city filter
                          _CityChip(
                            label: 'All',
                            isSelected: hostelCtrl.selectedCity.value.isEmpty,
                            onTap: () => hostelCtrl.applyFilters(city: ''),
                          ),
                          ...AppConstants.supportedCities.map(
                            (city) => _CityChip(
                              label: city,
                              isSelected: hostelCtrl.selectedCity.value == city,
                              onTap: () => hostelCtrl.applyFilters(city: city),
                            ),
                          ),
                        ],
                      )),
                ),
              ],
            ),
          ),

          // ── FR-9: Sort Mode Selector ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text(
                  'Sort by:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: hostelCtrl.sortMode.value,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'smart',     child: Text('⭐ Smart Ranking')),
                          DropdownMenuItem(value: 'rating',    child: Text('🌟 Highest Rating')),
                          DropdownMenuItem(value: 'priceLow',  child: Text('💰 Price: Low → High')),
                          DropdownMenuItem(value: 'priceHigh', child: Text('💎 Price: High → Low')),
                          DropdownMenuItem(value: 'newest',    child: Text('🆕 Newest First')),
                        ],
                        onChanged: (val) {
                          if (val != null) hostelCtrl.applySortMode(val);
                        },
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),

          // ── Hostel List ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              // Show loading shimmer while data loads
              if (hostelCtrl.approvedHostels.isEmpty &&
                  hostelCtrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (hostelCtrl.approvedHostels.isEmpty) {
                return const _EmptyState(
                  icon: Icons.home_work_outlined,
                  message: 'No hostels found.\nTry a different city or filter.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => hostelCtrl.loadApprovedHostels(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hostelCtrl.approvedHostels.length,
                  itemBuilder: (ctx, i) {
                    final hostel = hostelCtrl.approvedHostels[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: HostelCard(
                        hostel: hostel,
                        onTap: () {
                          // Pass hostel to detail screen via Get.arguments
                          Get.toNamed(
                            AppRoutes.hostelDetail,
                            arguments: hostel,
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),

      // ── FAB: Filter button ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFilterSheet(context, hostelCtrl),
        icon: const Icon(Icons.tune),
        label: const Text('Filter'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  // ── Bottom Sheet for advanced filters ─────────────────────────────────────
  void _showFilterSheet(BuildContext context, HostelController ctrl) {
    // Local temp values for filter (applied only on tap "Apply")
    double tempMin = ctrl.minRent.value;
    double tempMax = ctrl.maxRent.value;
    String tempGender = ctrl.selectedGender.value;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Filter Hostels',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),

              // ── Rent Range Slider ──────────────────────────────────────
              Text('Rent Range: PKR ${tempMin.round()} – ${tempMax.round()}'),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 50000,
                divisions: 50,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  tempMin = v.start;
                  tempMax = v.end;
                }),
              ),
              const SizedBox(height: 16),

              // ── Gender Filter ──────────────────────────────────────────
              const Text('Gender Preference'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', ...AppConstants.genderOptions].map((g) {
                  final selected = tempGender == (g == 'All' ? '' : g);
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    onSelected: (_) => setState(() {
                      tempGender = g == 'All' ? '' : g;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ctrl.clearFilters();
                        Get.back();
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ctrl.applyFilters(
                          gender: tempGender,
                          min: tempMin,
                          max: tempMax,
                        );
                        Get.back();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ── City filter chip ───────────────────────────────────────────────────────
class _CityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Empty state illustration ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar for students ────────────────────────────────────
class _StudentBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Track selected index in controller
    final RxInt selectedIndex = 0.obs;

    return Obx(() => BottomNavigationBar(
          currentIndex: selectedIndex.value,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            selectedIndex.value = i;
            switch (i) {
              case 0:
                break; // Already on home
              case 1:
                Get.toNamed(AppRoutes.myBookings);
                break;
              case 2:
                Get.toNamed(AppRoutes.myComplaints);
                break;
              case 3:
                Get.toNamed(AppRoutes.profile);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined),
              activeIcon: Icon(Icons.report),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ));
  }
}
