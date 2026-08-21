import 'package:flutter/material.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final AuthService _authService = Get.find<AuthService>();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _filterRole = 'all'; // 'all' | 'student' | 'owner' | 'admin'

  static const _roles = ['all', 'student', 'owner', 'admin'];

  @override
  void deactivate() {
    // Dismiss keyboard and drop focus whenever this tab is hidden
    _searchFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<UserModel> _applyFilters(List<UserModel> users) {
    return users.where((u) {
      final matchRole = _filterRole == 'all' || u.role == _filterRole;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search & filter bar ──────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search field
              TextField(
                focusNode: _searchFocusNode,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Role filter chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _roles.map((role) {
                    final selected = _filterRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filterRole = role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            role.capitalizeFirst ?? role,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── User list ────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _authService.getAllUsersStream(),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _applyFilters(snap.data!);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: AppColors.divider),
                      const SizedBox(height: 12),
                      Text('No users found',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _UserCard(user: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.adminUserDetail, arguments: user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar with role-colored border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _roleColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: _roleColor.withValues(alpha: 0.12),
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
                              color: _roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Role & status badges
                    Row(
                      children: [
                        _badge(
                          icon: _roleIcon,
                          label: user.role.capitalizeFirst ?? user.role,
                          color: _roleColor,
                        ),
                        const SizedBox(width: 8),
                        _badge(
                          icon: user.isActive
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          label: user.isActive ? 'Active' : 'Suspended',
                          color: user.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
