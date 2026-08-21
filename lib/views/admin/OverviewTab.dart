import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/admin/widgets/AdminStatCard.dart';
import 'package:get/get.dart';

class OverviewTab extends StatelessWidget {
  final HostelController hostelCtrl;
  final AuthController authCtrl = Get.find<AuthController>();
  
  final BookingService bookingService = Get.find<BookingService>();
  final AuthService authService = Get.find<AuthService>();

  OverviewTab({required this.hostelCtrl, super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF043b46), Color(0xFF108168)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white),
                          onPressed: () {}, // Add notification routing if needed
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                          onPressed: () => Get.toNamed(AppRoutes.profile),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Greeting Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'admin', // Hardcoded lowercase per mockup or dynamic without emoji
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Here's what's happening with your system today.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content Container ──────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Overview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Responsive Grid for Stats
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int columns = 2;
                          if (constraints.maxWidth > 600) columns = 4;
                          
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9, 
                            children: [
                              Obx(() => AdminStatCard(
                                    label: 'Registered\nHostels',
                                    value: '${hostelCtrl.allHostels.length}',
                                    icon: Icons.home_outlined,
                                    bgColor: const Color(0xFFEAF5F4),
                                    accentColor: const Color(0xFF1E5D57),
                                  )),
                              Obx(() => AdminStatCard(
                                    label: 'Approved\nHostels',
                                    value: '${hostelCtrl.allHostels.where((h) => h.status == "approved").length}',
                                    icon: Icons.verified_user_outlined,
                                    bgColor: const Color(0xFFEDF7ED),
                                    accentColor: const Color(0xFF2E6534),
                                  )),
                              StreamBuilder<List<BookingModel>>(
                                stream: bookingService.getAllBookingsStream(),
                                builder: (context, snapshot) {
                                  final count = snapshot.hasData ? snapshot.data!.length : 0;
                                  return AdminStatCard(
                                    label: 'Total\nBookings',
                                    value: '$count',
                                    icon: Icons.bookmark_border,
                                    bgColor: const Color(0xFFEDF2FB),
                                    accentColor: const Color(0xFF2D57A1),
                                  );
                                }
                              ),
                              StreamBuilder<List<UserModel>>(
                                stream: authService.getAllUsersStream(),
                                builder: (context, snapshot) {
                                  final count = snapshot.hasData ? snapshot.data!.length : 0;
                                  return AdminStatCard(
                                    label: 'Total\nAccounts',
                                    value: '$count',
                                    icon: Icons.manage_accounts_outlined,
                                    bgColor: const Color(0xFFFFF4E5),
                                    accentColor: const Color(0xFFB55B1D),
                                  );
                                }
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



