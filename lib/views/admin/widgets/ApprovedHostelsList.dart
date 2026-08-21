import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';

class HostelApprovalList extends StatelessWidget {
  final List<HostelModel> hostels;
  final String emptyMessage;
  final HostelController hostelCtrl;
  final bool showActions;

  const HostelApprovalList({
    super.key,
    required this.hostels,
    required this.emptyMessage,
    required this.hostelCtrl,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    if (hostels.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hostels.length,
      itemBuilder: (_, i) {
        final hostel = hostels[i];
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.adminHostelDetail, arguments: hostel),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hostel.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: hostel.images[0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.divider,
                                  child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.divider,
                                  child: const Icon(Icons.home_work_outlined),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: AppColors.divider,
                                child: const Icon(Icons.home_work_outlined)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hostel.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                                '${hostel.city} · ${hostel.roomType} · ${hostel.genderPreference}'),
                            Text(
                                'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      StatusChip(status: hostel.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: hostel.facilities
                        .take(3)
                        .map((f) => Chip(
                              label: Text(f,
                                  style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => hostelCtrl.updateHostelStatus(
                                hostel.id, AppConstants.statusRejected),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => hostelCtrl.updateHostelStatus(
                                hostel.id, AppConstants.statusApproved),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
