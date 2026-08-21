// lib/views/owner/owner_bookings_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-5.2: Owner accepts or rejects booking requests.
// FR-5.5: Owner views booking history.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingController ctrl = Get.find<BookingController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'All'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Obx(() {
          final all = ctrl.myBookings;
          final pending =
              all.where((b) => b.status == AppConstants.bookingPending).toList();
          final confirmed = all
              .where((b) => b.status == AppConstants.bookingConfirmed)
              .toList();

          return TabBarView(
            children: [
              _BookingList(
                bookings: pending,
                showActions: true,
                emptyMessage: 'No pending booking requests.',
                ctrl: ctrl,
              ),
              _BookingList(
                bookings: confirmed,
                showActions: false,
                emptyMessage: 'No confirmed bookings.',
                ctrl: ctrl,
              ),
              _BookingList(
                bookings: all,
                showActions: false,
                emptyMessage: 'No bookings yet.',
                ctrl: ctrl,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Booking list tab content ───────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool showActions;
  final String emptyMessage;
  final BookingController ctrl;

  const _BookingList({
    required this.bookings,
    required this.showActions,
    required this.emptyMessage,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final booking = bookings[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student info + status
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(booking.studentName[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primaryDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.studentName,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(booking.studentEmail,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    StatusChip(status: booking.status),
                  ],
                ),
                const Divider(height: 20),

                // Booking details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailItem(
                            label: 'Hostel',
                            value: booking.hostelName,
                          ),
                          _DetailItem(
                            label: 'Check-in',
                            value: DateFormat('MMM dd, yyyy')
                                .format(booking.checkInDate),
                          ),
                          _DetailItem(
                            label: 'Check-out',
                            value: DateFormat('MMM dd, yyyy')
                                .format(booking.checkOutDate),
                          ),
                          _DetailItem(
                            label: 'Total',
                            value: 'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Accept/Reject buttons (only for pending)
                if (showActions &&
                    booking.status == AppConstants.bookingPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Reject button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showResponseDialog(context, booking, false, ctrl),
                          icon: const Icon(Icons.close, color: AppColors.error),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showResponseDialog(context, booking, true, ctrl),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dialog to add optional note when accepting/rejecting ──────────────────
  void _showResponseDialog(
    BuildContext ctx,
    BookingModel booking,
    bool isAccepting,
    BookingController ctrl,
  ) {
    final noteCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(isAccepting ? 'Accept Booking' : 'Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAccepting
                  ? 'Accept booking request from ${booking.studentName}?'
                  : 'Reject booking request from ${booking.studentName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isAccepting
                    ? 'Optional: welcome message...'
                    : 'Optional: reason for rejection...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.respondToBooking(
                booking,
                isAccepting
                    ? AppConstants.bookingConfirmed
                    : AppConstants.bookingRejected,
                note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccepting ? AppColors.success : AppColors.error,
            ),
            child: Text(isAccepting ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
  }
}

// ── Simple key-value detail row ────────────────────────────────────────────
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

