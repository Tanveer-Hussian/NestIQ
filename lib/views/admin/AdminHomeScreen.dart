import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/admin/ComplaintsTab.dart';
import 'package:fyp/views/admin/HostelsTab.dart';
import 'package:fyp/views/admin/OverviewTab.dart';
import 'package:fyp/views/admin/ReviewsTab.dart';
import 'package:fyp/views/admin/UsersTab.dart';
import 'package:get/get.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final HostelController hostelCtrl;
  late final BookingController bookingCtrl;
  late final ReviewController reviewCtrl;
  late final ComplaintController complaintCtrl;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    hostelCtrl = Get.find<HostelController>();
    bookingCtrl = Get.find<BookingController>();
    reviewCtrl = Get.find<ReviewController>();
    complaintCtrl = Get.find<ComplaintController>();

    hostelCtrl.ensureAdminStreamsLoaded();
    reviewCtrl.loadFlaggedReviews();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          OverviewTab(hostelCtrl: hostelCtrl),
          _wrapWithAppBar('Hostels', HostelsTab(hostelCtrl: hostelCtrl)),
          _wrapWithAppBar('Users', const UsersTab()),
          _wrapWithAppBar('Complaints', ComplaintsTab(complaintCtrl: complaintCtrl)),
          _wrapWithAppBar('Reviews', ReviewsTab(reviewCtrl: reviewCtrl)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.domain_outlined),
              activeIcon: Icon(Icons.domain),
              label: 'Hostels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              activeIcon: Icon(Icons.star),
              label: 'Reviews',
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithAppBar(String title, Widget child) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Messages',
            onPressed: () => Get.toNamed(AppRoutes.adminChats),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: child,
    );
  }
}
