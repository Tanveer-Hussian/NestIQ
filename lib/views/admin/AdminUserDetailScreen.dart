import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late UserModel user;
  final AuthService _authService = Get.find<AuthService>();
  bool _isLoading = false;

  // Edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _universityCtrl;

  @override
  void initState() {
    super.initState();
    user = Get.arguments as UserModel;
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone);
    _universityCtrl = TextEditingController(text: user.university ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color get _roleColor {
    switch (user.role) {
      case 'admin':
        return AppColors.error;
      case 'owner':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData get _roleIcon {
    switch (user.role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'owner':
        return Icons.home_work_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  String get _formattedDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt);

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _toggleStatus() async {
    if (user.role == 'admin') {
      Get.snackbar('Not Allowed', 'Admin accounts cannot be suspended.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isLoading = true);
    await _authService.setUserActiveStatus(user.uid, !user.isActive);
    setState(() {
      user = user.copyWith(isActive: !user.isActive);
      _isLoading = false;
    });
    Get.snackbar(
      user.isActive ? 'Account Activated' : 'Account Suspended',
      user.isActive
          ? '${user.name} can now log in.'
          : '${user.name} has been suspended.',
      backgroundColor: user.isActive ? AppColors.success : AppColors.warning,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Edit User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Full Name', _nameCtrl, Icons.person_outline),
              const SizedBox(height: 12),
              _buildDialogField('Phone', _phoneCtrl, Icons.phone_outlined),
              if (user.role == 'student') ...[
                const SizedBox(height: 12),
                _buildDialogField(
                    'University', _universityCtrl, Icons.school_outlined),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _saveEdits,
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Future<void> _saveEdits() async {
    Get.back();
    setState(() => _isLoading = true);
    final updates = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (user.role == 'student')
        'university': _universityCtrl.text.trim(),
    };
    await _authService.updateUserProfile(user.uid, updates);
    setState(() {
      user = user.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        university: user.role == 'student' ? _universityCtrl.text.trim() : user.university,
      );
      _isLoading = false;
    });
    Get.snackbar('Updated', 'User profile has been updated.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
  }

  void _confirmDelete() {
    if (user.role == 'admin') {
      Get.snackbar('Not Allowed', 'Admin accounts cannot be deleted.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.defaultDialog(
      title: 'Delete User',
      titleStyle: const TextStyle(
          fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18),
      middleText:
          'Are you sure you want to permanently delete ${user.name}? This cannot be undone.',
      middleTextStyle: TextStyle(color: AppColors.textSecondary),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: _deleteUser,
        child: const Text('Delete', style: TextStyle(color: Colors.white)),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  Future<void> _deleteUser() async {
    Get.back();
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .delete();
    setState(() => _isLoading = false);
    Get.back(); // Pop detail screen
    Get.snackbar('Deleted', '${user.name} has been removed.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildAccountCard(),
                        if (user.role == 'owner') ...[
                          const SizedBox(height: 16),
                          _buildCnicCard(),
                          const SizedBox(height: 16),
                          _buildOwnerHostelsCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Sliver App Bar with avatar ─────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _roleColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _roleColor,
                _roleColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 2),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null || user.profileImage!.isEmpty
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _roleColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_roleIcon, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      user.role.capitalizeFirst ?? user.role,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit User',
          onPressed: _showEditDialog,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete User',
          onPressed: _confirmDelete,
        ),
      ],
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (user.isActive ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              user.isActive
                  ? Icons.check_circle_outline
                  : Icons.block_outlined,
              color: user.isActive ? AppColors.success : AppColors.error,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Status',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  user.isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color:
                        user.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          if (user.role != 'admin')
            Switch(
              value: user.isActive,
              activeColor: AppColors.success,
              onChanged: (_) => _toggleStatus(),
            ),
        ],
      ),
    );
  }

  // ── Personal info card ──────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _card(
      title: 'Personal Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email),
          _divider(),
          _infoRow(Icons.phone_outlined, 'Phone',
              user.phone.isNotEmpty ? user.phone : '—'),
          if (user.role == 'student') ...[
            _divider(),
            _infoRow(Icons.school_outlined, 'University',
                user.university?.isNotEmpty == true ? user.university! : '—'),
          ],
        ],
      ),
    );
  }

  // ── Account card ────────────────────────────────────────────────────────────
  Widget _buildAccountCard() {
    return _card(
      title: 'Account Details',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'User ID', user.uid,
              isMonospace: true),
          _divider(),
          _infoRow(Icons.category_outlined, 'Role',
              user.role.capitalizeFirst ?? user.role),
          _divider(),
          _infoRow(
              Icons.calendar_today_outlined, 'Registered On', _formattedDate),
        ],
      ),
    );
  }

  Widget _buildCnicCard() {
    if (user.cnicImageUrl == null || user.cnicImageUrl!.isEmpty) {
      return _card(
        title: 'CNIC (Front Side)',
        icon: Icons.credit_card_outlined,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No CNIC image uploaded.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return _card(
      title: 'CNIC (Front Side)',
      icon: Icons.credit_card_outlined,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () {
            Get.dialog(
              Dialog(
                backgroundColor: Colors.transparent,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(user.cnicImageUrl!, fit: BoxFit.contain),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: 1.586, // Standard credit card/ID ratio
            child: Container(
              color: AppColors.background,
              child: Image.network(
                user.cnicImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Owner hostels card ──────────────────────────────────────────────────────
  Widget _buildOwnerHostelsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colHostels)
          .where('ownerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return _card(
            title: 'Registered Hostels',
            icon: Icons.home_work_outlined,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        final hostels = snap.data!.docs
            .map((d) =>
                HostelModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();

        return _card(
          title: 'Registered Hostels (${hostels.length})',
          icon: Icons.home_work_outlined,
          child: hostels.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No hostels registered yet.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : Column(
                  children: hostels
                      .map((h) => _hostelTile(h))
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _hostelTile(HostelModel h) {
    final statusColor = h.status == 'approved'
        ? AppColors.success
        : h.status == 'pending'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Hostel thumbnail or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: h.images.isNotEmpty
                ? Image.network(h.images.first,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _hostelPlaceholder())
                : _hostelPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${h.city} · PKR ${h.rentPerMonth.toStringAsFixed(0)}/mo',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 13, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(h.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.reviews_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text('${h.totalReviews} reviews',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              h.status.capitalizeFirst ?? h.status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hostelPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Icon(Icons.home_outlined, color: AppColors.primary, size: 28),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(
              user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
              size: 18,
            ),
            label: Text(
                user.isActive ? 'Suspend Account' : 'Activate Account'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  user.isActive ? AppColors.error : AppColors.success,
              side: BorderSide(
                  color: user.isActive ? AppColors.error : AppColors.success),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: user.role == 'admin' ? null : _toggleStatus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever_outlined,
                size: 18, color: Colors.white),
            label: const Text('Delete User',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: user.role == 'admin' ? null : _confirmDelete,
          ),
        ),
      ],
    );
  }

  // ── Reusable card wrapper ───────────────────────────────────────────────────
  Widget _card({Widget? child, String? title, IconData? icon}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && icon != null) ...[
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.divider, height: 1, thickness: 1);
}
