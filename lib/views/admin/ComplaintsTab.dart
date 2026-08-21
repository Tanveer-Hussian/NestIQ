// ─────────────────────────────────────────────────────────────────────────────
// lib/views/admin/ComplaintsTab.dart
// FR-7.4: Admin can view all complaints system-wide and monitor resolution.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintsTab extends StatefulWidget {
  final ComplaintController complaintCtrl;
  const ComplaintsTab({required this.complaintCtrl, super.key});

  @override
  State<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  String _filter = 'all'; // 'all' | 'pending' | 'in_progress' | 'resolved'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter Chips ──────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'All', value: 'all', current: _filter,
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: '⏳ Pending', value: 'pending', current: _filter,
                    onTap: () => setState(() => _filter = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(label: '🔄 In Progress', value: 'in_progress', current: _filter,
                    onTap: () => setState(() => _filter = 'in_progress')),
                const SizedBox(width: 8),
                _FilterChip(label: '✅ Resolved', value: 'resolved', current: _filter,
                    onTap: () => setState(() => _filter = 'resolved')),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Complaints list ───────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            List<ComplaintModel> complaints = widget.complaintCtrl.allComplaints;

            if (_filter != 'all') {
              complaints = complaints.where((c) => c.status == _filter).toList();
            }

            if (complaints.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 72,
                        color: AppColors.success.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _filter == 'all'
                          ? 'No complaints in the system.'
                          : 'No ${_filter.replaceAll('_', ' ')} complaints.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (_, i) => _AdminComplaintCard(complaint: complaints[i]),
            );
          }),
        ),
      ],
    );
  }
}

// ── Filter chip widget ─────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Single admin complaint card ────────────────────────────────────────────
class _AdminComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _AdminComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint.status;
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case 'resolved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.autorenew;
        break;
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        complaint.hostelName,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Meta row ──────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'By ${complaint.studentName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(complaint.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Description ───────────────────────────────────────────────
            Text(
              complaint.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),

            // ── Owner response (if any) ────────────────────────────────────
            if (complaint.ownerResponse != null &&
                complaint.ownerResponse!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner Response:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.ownerResponse!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
