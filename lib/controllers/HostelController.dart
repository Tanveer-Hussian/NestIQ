// lib/controllers/HostelController.dart

import 'dart:async';
import 'dart:io';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/services/RankingService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';

class HostelController extends GetxController {

  final HostelService _hostelService = Get.find<HostelService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final AuthController _authController = Get.find<AuthController>();

  // ── Observable lists ──────────────────────────────────────────────────────
  final RxList<HostelModel> approvedHostels = <HostelModel>[].obs;
  final RxList<HostelModel> ownerHostels    = <HostelModel>[].obs;
  final RxList<HostelModel> pendingHostels  = <HostelModel>[].obs;
  final RxList<HostelModel> allHostels      = <HostelModel>[].obs;
  final RxList<HostelModel> searchResults   = <HostelModel>[].obs;
  final RxString            searchQuery     = ''.obs;

  // ── Form / UI state ───────────────────────────────────────────────────────
  final RxBool   isLoading       = false.obs;
  final RxBool   isUploading     = false.obs;
  final RxInt    uploadProgress  = 0.obs;
  final RxString errorMessage    = ''.obs;

  // ── Search & Filter state ─────────────────────────────────────────────────
  final RxString       selectedCity       = ''.obs;
  final RxString       selectedGender     = ''.obs;
  final RxDouble       minRent            = 0.0.obs;
  final RxDouble       maxRent            = 50000.0.obs;
  final RxList<String> selectedFacilities = <String>[].obs;

  // ── FR-9: Sort / Ranking mode ─────────────────────────────────────────
  // 'smart' = composite score | 'rating' | 'priceLow' | 'priceHigh' | 'newest'
  final RxString sortMode = 'smart'.obs;

  // ── Stream subscriptions (stored so we can cancel before re-subscribing) ──
  StreamSubscription<List<HostelModel>>? _approvedSub;
  StreamSubscription<List<HostelModel>>? _ownerSub;
  StreamSubscription<List<HostelModel>>? _pendingSub;
  StreamSubscription<List<HostelModel>>? _allHostelsSub;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadApprovedHostels();

    if (_authController.isOwner) loadOwnerHostels();
    if (_authController.isAdmin) {
      loadAllHostels();
      loadPendingHostels();
    }
  }

  void ensureAdminStreamsLoaded() {
  loadAllHostels();
  loadPendingHostels();
}

  // ── Always cancel the old subscription before opening a new one ───────────
  // This prevents duplicate listeners from stacking up when these methods
  // are called more than once (e.g. after applyFilters / clearFilters).

  void loadApprovedHostels() {
    _approvedSub?.cancel();
    _approvedSub = _hostelService
        .getApprovedHostelsStream(
          city: selectedCity.value.isEmpty ? null : selectedCity.value,
          genderPreference:
              selectedGender.value.isEmpty ? null : selectedGender.value,
          minRent: minRent.value > 0      ? minRent.value : null,
          maxRent: maxRent.value < 50000  ? maxRent.value : null,
        )
        .listen(
          (hostels) => approvedHostels.value = _applySortMode(hostels),
          onError: (e) {
            errorMessage.value = 'Failed to load approved hostels: $e';
          },
        );
  }

  // ── FR-9: Apply sort mode to hostel list ───────────────────────────────
  List<HostelModel> _applySortMode(List<HostelModel> hostels) {
    switch (sortMode.value) {
      case 'smart':
        return RankingService.scoreAndSort(hostels);
      case 'rating':
        return hostels..sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case 'priceLow':
        return hostels..sort((a, b) => a.rentPerMonth.compareTo(b.rentPerMonth));
      case 'priceHigh':
        return hostels..sort((a, b) => b.rentPerMonth.compareTo(a.rentPerMonth));
      case 'newest':
      default:
        return hostels..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  // ── FR-9: Change sort mode and re-sort current list ──────────────────
  void applySortMode(String mode) {
    sortMode.value = mode;
    approvedHostels.value = _applySortMode(List.from(approvedHostels));
  }

  void loadOwnerHostels() {
    _ownerSub?.cancel();
    final ownerId = _authController.currentUser.value?.uid ?? '';
    _ownerSub = _hostelService
        .getOwnerHostelsStream(ownerId)
        .listen(
          (hostels) => ownerHostels.value = hostels,
          onError: (e) {
            errorMessage.value = 'Failed to load owner hostels: $e';
          },
        );
  }

  void loadPendingHostels() {
    _pendingSub?.cancel();
    _pendingSub = _hostelService
        .getPendingHostelsStream()
        .listen(
          (hostels) => pendingHostels.value = hostels,
          onError: (e) {
            errorMessage.value = 'Failed to load pending hostels: $e';
          },
        );
  }

  void loadAllHostels() {
    _allHostelsSub?.cancel();
    _allHostelsSub = _hostelService
        .getAllHostelsStream()
        .listen(
          (hostels) => allHostels.value = hostels,
          onError: (e) {
            errorMessage.value = 'Failed to load all hostels: $e';
          },
        );
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  void applyFilters({
    String? city,
    String? gender,
    double? min,
    double? max,
    List<String>? facilities,
  }) {
    if (city        != null) selectedCity.value       = city;
    if (gender      != null) selectedGender.value     = gender;
    if (min         != null) minRent.value             = min;
    if (max         != null) maxRent.value             = max;
    if (facilities  != null) selectedFacilities.value = facilities;
    // Cancels old approved stream and opens a fresh one with new filters
    loadApprovedHostels();
  }

  void clearFilters() {
    selectedCity.value      = '';
    selectedGender.value    = '';
    minRent.value           = 0.0;
    maxRent.value           = 50000.0;
    selectedFacilities.clear();
    loadApprovedHostels();
  }

  void searchHostels(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    final lowercaseQuery = query.trim().toLowerCase();
    searchResults.value = approvedHostels.where((h) {
      return h.name.toLowerCase().contains(lowercaseQuery) ||
          h.city.toLowerCase().contains(lowercaseQuery) ||
          h.address.toLowerCase().contains(lowercaseQuery) ||
          h.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // ── onClose: cancel all streams when the controller is destroyed ──────────
  @override
  void onClose() {
    _approvedSub?.cancel();
    _ownerSub?.cancel();
    _pendingSub?.cancel();
    _allHostelsSub?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FR-3.1 & FR-3.2: Add hostel with Cloudinary image upload
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> addHostel({
    required String       name,
    required String       description,
    required String       city,
    required String       address,
    required double       latitude,
    required double       longitude,
    required double       rentPerMonth,
    required String       roomType,
    required String       genderPreference,
    required List<String> facilities,
    required List<File>   imageFiles,
    required int          totalRooms,
  }) async {
    try {
      isLoading.value     = true;
      errorMessage.value  = '';

      final owner = _authController.currentUser.value!;

      // Step 1: Create Firestore document to get the hostelId
      final tempHostel = HostelModel(
        id:               '',
        ownerId:          owner.uid,
        ownerName:        owner.name,
        name:             name,
        description:      description,
        city:             city,
        address:          address,
        latitude:         latitude,
        longitude:        longitude,
        rentPerMonth:     rentPerMonth,
        roomType:         roomType,
        genderPreference: genderPreference,
        facilities:       facilities,
        images:           [],
        totalRooms:       totalRooms,
        availableRooms:   totalRooms,
        createdAt:        DateTime.now(),
        updatedAt:        DateTime.now(),
      );

      final hostelId = await _hostelService.addHostel(tempHostel);

      // Step 2: Upload images to Cloudinary
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        isUploading.value = true;

        imageUrls = await _cloudinaryService.uploadMultipleImages(
          hostelId,
          imageFiles,
          onProgress: (uploaded, total) {
            uploadProgress.value = ((uploaded / total) * 100).round();
          },
        );

        isUploading.value = false;
      }

      // Step 3: Update Firestore with Cloudinary image URLs
      if (imageUrls.isNotEmpty) {
        await _hostelService.updateHostel(hostelId, {'images': imageUrls});
      }

      Get.snackbar(
        'Listing Submitted ✅',
        'Your hostel is pending admin approval.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;

    } catch (e) {
      errorMessage.value = 'Failed to add hostel: $e';
      return false;
    } finally {
      isLoading.value   = false;
      isUploading.value = false;
    }
  }

  Future<bool> updateHostel(String hostelId, Map<String, dynamic> updates) async {
    try {
      isLoading.value = true;
      await _hostelService.updateHostel(hostelId, updates);
      Get.snackbar('Updated', 'Hostel updated successfully.');
      return true;
    } catch (e) {
      errorMessage.value = 'Update failed: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteHostel(String hostelId) async {
    try {
      await _hostelService.deleteHostel(hostelId);
      Get.snackbar('Deleted', 'Hostel listing removed.');
      return true;
    } catch (e) {
      errorMessage.value = 'Delete failed: $e';
      return false;
    }
  }

  Future<void> updateHostelStatus(String hostelId, String status) async {
    try {
      await _hostelService.updateHostelStatus(hostelId, status);
      final msg = status == AppConstants.statusApproved ? 'approved' : 'rejected';
      Get.snackbar('Done', 'Hostel listing $msg.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status.');
    }
  }
}
