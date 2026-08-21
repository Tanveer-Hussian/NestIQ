// ─────────────────────────────────────────────────────────────────────────────
// lib/views/owner/owner_complaints_screen.dart
// FR-7.2: Owner responds to complaints from residents.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart' show StatusChip;
import 'package:get/get.dart';

class OwnerComplaintsScreen extends StatelessWidget {
  const OwnerComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ComplaintController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Complaints')),
      body: Obx(() {
        final complaints = ctrl.myComplaints;

        if (complaints.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('No complaints!',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) {
            final c = complaints[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.title,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        StatusChip(status: c.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('by ${c.studentName} · ${c.hostelName}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Divider(height: 20),

                    // Complaint description
                    Text(c.description),

                    // Existing response if any
                    if (c.ownerResponse != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Response:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12)),
                            Text(c.ownerResponse!),
                          ],
                        ),
                      ),
                    ],

                    // Respond button (only for pending/in-progress)
                    if (c.status != AppConstants.complaintResolved) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showRespondDialog(context, c, ctrl),
                          icon: const Icon(Icons.reply_outlined, size: 16),
                          label: const Text('Respond'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showRespondDialog(BuildContext ctx, complaint, ctrl) {
    final responseCtrl =
        TextEditingController(text: complaint.ownerResponse ?? '');
    String selectedStatus = complaint.status == 'pending'
        ? AppConstants.complaintInProgress
        : AppConstants.complaintResolved;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Respond to Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your response to the student...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Update Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('🔄 In Progress')),
                  DropdownMenuItem(
                      value: 'resolved', child: Text('✅ Resolved')),
                ],
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                ctrl.respondToComplaint(
                    complaint, responseCtrl.text, selectedStatus);
              },
              child: const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }
}
