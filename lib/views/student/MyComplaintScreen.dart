// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/my_complaints_screen.dart
// FR-7.3: Student tracks their complaint status.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared Widgets/StatusChip.dart';
import 'package:get/get.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ComplaintController>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: Obx(() {
        final complaints = ctrl.myComplaints;

        if (complaints.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('No complaints filed.',
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
              child: ExpansionTile(
                leading: StatusChip(status: c.status),
                title: Text(c.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.hostelName),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text('Your Complaint:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(c.description),
                        if (c.ownerResponse != null) ...[
                          const SizedBox(height: 12),
                          const Text('Owner Response:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(c.ownerResponse!),
                          // Show confirmation actions if owner marked resolved but student not yet confirmed
                          if (c.status == 'resolved' && !c.studentConfirmed) ...[
                            const SizedBox(height: 12),
                            const Text('Is the issue resolved?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                    onPressed: () => Get.find<ComplaintController>()
                                        .confirmResolution(c, true),
                                    child: const Text('Confirmed'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    onPressed: () => Get.find<ComplaintController>()
                                        .confirmResolution(c, false),
                                    child: const Text('Not Resolved'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
