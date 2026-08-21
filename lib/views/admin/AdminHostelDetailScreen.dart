import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHostelDetailScreen extends StatefulWidget {
  const AdminHostelDetailScreen({super.key});

  @override
  State<AdminHostelDetailScreen> createState() => _AdminHostelDetailScreenState();
}

class _AdminHostelDetailScreenState extends State<AdminHostelDetailScreen> {
  late final HostelModel hostel = Get.arguments as HostelModel;
  final HostelController hostelCtrl = Get.find<HostelController>();
  final ChatController chatCtrl = Get.find<ChatController>();
  final AuthService authService = Get.find<AuthService>();
  final NotificationService _notifService = Get.find<NotificationService>();
  int _currentImageIndex = 0;
  late Future<UserModel?> _ownerFuture;

  @override
  void initState() {
    super.initState();
    _ownerFuture = authService.getUserById(hostel.ownerId);
  }

  Future<void> _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${hostel.latitude},${hostel.longitude}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open Google Maps.');
    }
  }

  Future<void> _sendWarning() async {
    final ctrl = TextEditingController();
    await Get.defaultDialog(
      title: 'Send Final Warning',
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: 'Enter warning reason...'),
        maxLines: 3,
      ),
      textConfirm: 'Send',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        if (ctrl.text.isEmpty) return;
        Get.back(); // close dialog
        await _notifService.sendNotification(
          userId: hostel.ownerId,
          title: 'FINAL WARNING',
          body: ctrl.text,
          type: 'warning',
          relatedId: hostel.id,
        );
        Get.snackbar(
          'Warning Sent',
          'The owner has been notified.',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      },
    );
  }

  void _confirmRemove() {
    Get.defaultDialog(
      title: 'Remove Hostel',
      middleText: 'Are you sure you want to completely remove this hostel listing?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back(); // close dialog
        final ok = await hostelCtrl.deleteHostel(hostel.id);
        if (ok) {
          Get.back(); // close screen
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(hostel.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Request Details'),
        backgroundColor: AppColors.primary,
        actions: [
          Obx(() {
            if (chatCtrl.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.chat_outlined, color: Colors.white),
              tooltip: 'Message Owner',
              onPressed: () async {
                final roomId = await chatCtrl.startOrGetConversation(
                  ownerId: hostel.ownerId,
                  ownerName: hostel.ownerName,
                  ownerEmail: '',
                );
                Get.toNamed(
                  AppRoutes.chatConversation,
                  arguments: {
                    'roomId': roomId,
                    'title': hostel.ownerName,
                  },
                );
              },
            );
          }),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                Get.toNamed(AppRoutes.addHostel, arguments: hostel);
              } else if (val == 'warning') {
                _sendWarning();
              } else if (val == 'remove') {
                _confirmRemove();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit Hostel'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'warning',
                child: ListTile(
                  leading: Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  title: Text('Send Final Warning'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Remove Hostel', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Slider ──────────────────────────────────────────────────
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  color: AppColors.divider,
                  child: hostel.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: hostel.images.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (ctx, i) => CachedNetworkImage(
                            imageUrl: hostel.images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.home_work_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.home_work_outlined,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                ),
                if (hostel.images.length > 1)
                  Positioned(
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        hostel.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentImageIndex == i ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hostel.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      StatusChip(status: hostel.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rent and availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${hostel.rentPerMonth.toStringAsFixed(0)} / month',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Rooms: ${hostel.availableRooms}/${hostel.totalRooms} available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // ── Hostel Owner Details ──────────────────────────────────────────
                  const Text(
                    'Hostel Owner & Submission Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: FutureBuilder<UserModel?>(
                      future: _ownerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${hostel.ownerName}', style: const TextStyle(fontSize: 14)),
                              const Text('Email: Unable to fetch email', style: TextStyle(fontSize: 14, color: AppColors.error)),
                              Text('Submitted: $formattedDate', style: const TextStyle(fontSize: 14)),
                            ],
                          );
                        }

                        final owner = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${owner.name}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${owner.email}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${owner.phone}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted At: $formattedDate',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (owner.cnicImageUrl != null && owner.cnicImageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Owner CNIC (Front Side):',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
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
                                              child: Image.network(owner.cnicImageUrl!, fit: BoxFit.contain),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 1.586,
                                    child: Image.network(
                                      owner.cnicImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.broken_image_outlined, size: 40),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Message Owner Button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Message Owner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final roomId = await chatCtrl.startOrGetConversation(
                          ownerId: hostel.ownerId,
                          ownerName: hostel.ownerName,
                          ownerEmail: '',
                        );
                        Get.toNamed(
                          AppRoutes.chatConversation,
                          arguments: {
                            'roomId': roomId,
                            'title': hostel.ownerName,
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),

                  // Specs: Room type, Gender Pref
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecTile(
                          icon: Icons.meeting_room_outlined,
                          title: 'Room Type',
                          value: hostel.roomType,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpecTile(
                          icon: Icons.people_outline,
                          title: 'Gender Preference',
                          value: hostel.genderPreference,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location address & Google Maps preview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hostel.city}, Pakistan',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hostel.address,
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Coordinates: ${hostel.latitude.toStringAsFixed(6)}, ${hostel.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openMaps,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('View Map'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      // flutter_map — OpenStreetMap (no API key needed)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(hostel.latitude, hostel.longitude),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.fyp',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(hostel.latitude, hostel.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hostel.description,
                    style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 24),

                  // Facilities
                  const Text(
                    'Facilities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hostel.facilities.map((f) {
                      return Chip(
                        label: Text(f),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.divider),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80), // extra padding for bottom actions
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Actions panel if pending ──────────────────────────────────────────
      bottomNavigationBar: hostel.status == AppConstants.statusPending
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await hostelCtrl.updateHostelStatus(hostel.id, AppConstants.statusRejected);
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Reject Listing'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await hostelCtrl.updateHostelStatus(hostel.id, AppConstants.statusApproved);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Approve Listing'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSpecTile({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
