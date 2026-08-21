// lib/views/student/booking_request_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-5.1: Student selects check-in/out dates and submits a booking request.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  late final HostelModel hostel = Get.arguments as HostelModel;
  final BookingController bookingCtrl = Get.find<BookingController>();

  // Selected dates
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Date formatter
  final DateFormat _fmt = DateFormat('MMM dd, yyyy');

  // ── Date picker helper ─────────────────────────────────────────────────────
  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (now.add(const Duration(days: 1)))
          : (_checkInDate?.add(const Duration(days: 30)) ??
              now.add(const Duration(days: 31))),
      firstDate: isCheckIn ? now : (_checkInDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Reset check-out if it's before new check-in
          if (_checkOutDate != null &&
              _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  // ── Calculate months and total cost ───────────────────────────────────────
  double get _estimatedMonths {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays / 30;
  }

  double get _totalCost => hostel.rentPerMonth * _estimatedMonths;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Hostel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hostel Summary Card ──────────────────────────────────────────
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hostel.images.isNotEmpty
                      ? Image.network(hostel.images[0],
                          width: 60, height: 60, fit: BoxFit.cover)
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.divider,
                          child: const Icon(Icons.home_work_outlined),
                        ),
                ),
                title: Text(hostel.name,
                    style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text(hostel.city),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Text('/month',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Date Pickers ──────────────────────────────────────────────────
            Text('Select Dates', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            Row(
              children: [
                // Check-in date
                Expanded(
                  child: _DatePickerCard(
                    label: 'Check-In',
                    date: _checkInDate,
                    formatter: _fmt,
                    icon: Icons.login_outlined,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                // Check-out date
                Expanded(
                  child: _DatePickerCard(
                    label: 'Check-Out',
                    date: _checkOutDate,
                    formatter: _fmt,
                    icon: Icons.logout_outlined,
                    onTap: () => _pickDate(false),
                    isDisabled: _checkInDate == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Cost Summary ──────────────────────────────────────────────────
            if (_checkInDate != null && _checkOutDate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _CostRow(
                        label: 'Monthly Rent',
                        value:
                            'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}'),
                    _CostRow(
                        label: 'Duration',
                        value:
                            '${_estimatedMonths.toStringAsFixed(1)} months'),
                    const Divider(),
                    _CostRow(
                      label: 'Estimated Total',
                      value: 'PKR ${_totalCost.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Notice ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your booking request will be sent to the owner for approval. '
                      'You will be notified once a decision is made.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ─────────────────────────────────────────────────
            Obx(() => CustomButton(
                  text: 'Send Booking Request',
                  isLoading: bookingCtrl.isLoading.value,
                  icon: Icons.send_outlined,
                  onPressed: (_checkInDate != null && _checkOutDate != null)
                      ? () async {
                          final success = await bookingCtrl.requestBooking(
                            hostel: hostel,
                            checkInDate: _checkInDate!,
                            checkOutDate: _checkOutDate!,
                          );
                          if (success) Get.back();
                        }
                      : null,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Date picker card ───────────────────────────────────────────────────────
class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat formatter;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.formatter,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.divider : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.divider,
            width: date != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? formatter.format(date!) : 'Select date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cost breakdown row ─────────────────────────────────────────────────────
class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _CostRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 14,
                color: isTotal ? AppColors.primary : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/my_bookings_screen.dart
// FR-5.5: Student's booking history.
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingController ctrl = Get.find<BookingController>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Obx(() {
        final bookings = ctrl.myBookings;

        if (bookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: AppColors.divider),
                SizedBox(height: 16),
                Text('No bookings yet.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
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
                    // Hostel name + status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.hostelName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dates
                    _BookingInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Check-in',
                      value: DateFormat('MMM dd, yyyy').format(booking.checkInDate),
                    ),
                    _BookingInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Check-out',
                      value: DateFormat('MMM dd, yyyy').format(booking.checkOutDate),
                    ),
                    _BookingInfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Total',
                      value: 'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                    ),

                    // Owner's note if any
                    if (booking.ownerNote != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.comment_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Owner: ${booking.ownerNote}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Cancel button for pending/confirmed bookings
                    if (booking.status == 'pending' ||
                        booking.status == 'confirmed') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _confirmCancel(context, ctrl, booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                    ],

                    // Write review for completed stays
                    if (booking.status == 'confirmed') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(
                            AppRoutes.writeReview,
                            arguments: booking.hostelId,
                          ),
                          icon: const Icon(Icons.star_outline, size: 16),
                          label: const Text('Write a Review'),
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

  // ── Confirmation dialog before cancelling ──────────────────────────────────
  void _confirmCancel(BuildContext ctx, BookingController ctrl, booking) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.cancelBooking(booking);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Booking detail row ─────────────────────────────────────────────────────
class _BookingInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookingInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
