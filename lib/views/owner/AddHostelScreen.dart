// lib/views/owner/add_hostel_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-3.1, FR-3.2, FR-3.3: Owner creates or edits a hostel listing.
// Supports image upload, map location picker, facilities checkboxes.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';



class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  State<AddHostelScreen> createState() => _AddHostelScreenState();
}


class _AddHostelScreenState extends State<AddHostelScreen> {
  // If arguments provided, we're in edit mode
  final HostelModel? _editHostel = Get.arguments as HostelModel?;
  bool get _isEditing => _editHostel != null;

  final _formKey = GlobalKey<FormState>();
  final HostelController _hostelCtrl = Get.find<HostelController>();
  final ImagePicker _picker = ImagePicker();

  // ── Form controllers ───────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _roomsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _mapsUrlCtrl;
  final MapController _mapController = MapController();

  // ── Form state ─────────────────────────────────────────────────────────────
  String _selectedCity = AppConstants.supportedCities[0];
  String _selectedRoomType = AppConstants.roomTypes[0];
  String _selectedGender = AppConstants.genderOptions[0];
  List<String> _selectedFacilities = [];
  List<File> _selectedImages = [];      // new images to upload
  List<String> _existingImages = [];    // already uploaded URLs (edit mode)
  double _lat = 25.3792;                // default: Hyderabad, Pakistan
  double _lng = 68.3682;

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing
    _nameCtrl = TextEditingController(text: _editHostel?.name ?? '');
    _descCtrl = TextEditingController(text: _editHostel?.description ?? '');
    _addressCtrl = TextEditingController(text: _editHostel?.address ?? '');
    _rentCtrl = TextEditingController(
        text: _editHostel?.rentPerMonth.toStringAsFixed(0) ?? '');
    _roomsCtrl = TextEditingController(
        text: _editHostel?.totalRooms.toString() ?? '1');

    if (_isEditing) {
      _selectedCity = _editHostel!.city;
      _selectedRoomType = _editHostel!.roomType;
      _selectedGender = _editHostel!.genderPreference;
      _selectedFacilities = List.from(_editHostel!.facilities);
      _existingImages = List.from(_editHostel!.images);
      _lat = _editHostel!.latitude;
      _lng = _editHostel!.longitude;
    }

    _latCtrl = TextEditingController(text: _lat.toStringAsFixed(6));
    _lngCtrl = TextEditingController(text: _lng.toStringAsFixed(6));
    _mapsUrlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _rentCtrl.dispose();
    _roomsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapsUrlCtrl.dispose();
    super.dispose();
  }

  // ── Pick images from gallery ───────────────────────────────────────────────
  Future<void> _pickImages() async {
    final List<XFile> files = await _picker.pickMultiImage(
      imageQuality: 70, // compress to reduce upload size
    );
    if (files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(files.map((f) => File(f.path)));
      });
    }
  }

  // ── Get device current location ────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        Get.snackbar('Permission Denied', 'Please enable location in settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _latCtrl.text = _lat.toStringAsFixed(6);
        _lngCtrl.text = _lng.toStringAsFixed(6);
      });
      _mapController.move(LatLng(_lat, _lng), 15);
      Get.snackbar('Location Set', 'Hostel location updated to current GPS position.');
    } catch (e) {
      Get.snackbar('Error', 'Could not get location: $e');
    }
  }

  // ── Parse Google Maps link / coordinates input ─────────────────────────────
  void _parseMapsInput(String input) {
    if (input.trim().isEmpty) return;

    final regExp = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final match = regExp.firstMatch(input);
    if (match != null) {
      final parsedLat = double.tryParse(match.group(1) ?? '');
      final parsedLng = double.tryParse(match.group(2) ?? '');
      if (parsedLat != null && parsedLng != null) {
        setState(() {
          _lat = parsedLat;
          _lng = parsedLng;
          _latCtrl.text = _lat.toStringAsFixed(6);
          _lngCtrl.text = _lng.toStringAsFixed(6);
        });
        _mapController.move(LatLng(_lat, _lng), 15);
        Get.snackbar('Location Updated', 'Coordinates set to ($parsedLat, $parsedLng)');
        return;
      }
    }
    Get.snackbar('Invalid Link', 'Could not extract valid latitude & longitude.');
  }

  // ── Form submission ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      Get.snackbar('Images Required', 'Please add at least one photo.');
      return;
    }

    if (_isEditing) {
      // Edit mode: update fields (images handled separately)
      final updates = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'city': _selectedCity,
        'address': _addressCtrl.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'rentPerMonth': double.tryParse(_rentCtrl.text) ?? 0,
        'roomType': _selectedRoomType,
        'genderPreference': _selectedGender,
        'facilities': _selectedFacilities,
        'totalRooms': int.tryParse(_roomsCtrl.text) ?? 1,
      };
      final ok = await _hostelCtrl.updateHostel(_editHostel!.id, updates);
      if (ok) Get.back();
    } else {
      // Add mode: create new listing
      final ok = await _hostelCtrl.addHostel(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        city: _selectedCity,
        address: _addressCtrl.text.trim(),
        latitude: _lat,
        longitude: _lng,
        rentPerMonth: double.tryParse(_rentCtrl.text) ?? 0,
        roomType: _selectedRoomType,
        genderPreference: _selectedGender,
        facilities: _selectedFacilities,
        imageFiles: _selectedImages,
        totalRooms: int.tryParse(_roomsCtrl.text) ?? 1,
      );
      if (ok) {
        Get.snackbar(
          '✅ Submitted!',
          'Hostel submitted for approval. We\'ll notify you once reviewed.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.back();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Hostel' : 'Add New Hostel'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Basic Info ──────────────────────────────────────────
            _FormSection(title: 'Basic Information'),
            const SizedBox(height: 12),

            CustomTextField(
              controller: _nameCtrl,
              label: 'Hostel Name *',
              prefixIcon: Icons.home_work_outlined,
              validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),

            // City dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'City *',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: AppConstants.supportedCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v!),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _addressCtrl,
              label: 'Full Address *',
              prefixIcon: Icons.pin_drop_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _descCtrl,
              label: 'Description *',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.length < 20 ? 'Min 20 characters' : null,
            ),
            const SizedBox(height: 24),

            // ── Section: Room Details ────────────────────────────────────────
            _FormSection(title: 'Room Details'),
            const SizedBox(height: 12),

            Row(
              children: [
                // Rent field
                Expanded(
                  child: CustomTextField(
                    controller: _rentCtrl,
                    label: 'Monthly Rent (PKR) *',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Total rooms field
                Expanded(
                  child: CustomTextField(
                    controller: _roomsCtrl,
                    label: 'Total Rooms *',
                    prefixIcon: Icons.meeting_room_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Room type dropdown
            DropdownButtonFormField<String>(
              value: _selectedRoomType,
              decoration: const InputDecoration(
                labelText: 'Room Type *',
                prefixIcon: Icon(Icons.hotel_outlined),
              ),
              items: AppConstants.roomTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoomType = v!),
            ),
            const SizedBox(height: 16),

            // Gender preference dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender Preference *',
                prefixIcon: Icon(Icons.people_outline),
              ),
              items: AppConstants.genderOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v!),
            ),
            const SizedBox(height: 24),

            // ── Section: Facilities ──────────────────────────────────────────
            _FormSection(title: 'Facilities'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.facilities.map((f) {
                final selected = _selectedFacilities.contains(f);
                return FilterChip(
                  label: Text(f),
                  selected: selected,
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primaryDark,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedFacilities.remove(f);
                    } else {
                      _selectedFacilities.add(f);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Section: Photos ─────────────────────────────────────────────
            _FormSection(title: 'Photos'),
            const SizedBox(height: 12),

            // Image grid (existing + new)
            if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images (from URLs)
                    ..._existingImages.map((url) => _ImageThumb.network(
                          url: url,
                          onRemove: () =>
                              setState(() => _existingImages.remove(url)),
                        )),
                    // New images (from local files)
                    ..._selectedImages.map((file) => _ImageThumb.file(
                          file: file,
                          onRemove: () =>
                              setState(() => _selectedImages.remove(file)),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Pick more images button
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Photos'),
            ),
            const SizedBox(height: 24),


            // ── Section: Google Maps Location ───────────────────────────────
            _FormSection(title: 'Google Maps Location *'),
            const SizedBox(height: 6),
            const Text(
              'Specify the exact location of your hostel. You can drag the pin on the map, tap any location, use GPS, or enter/paste coordinates.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Map preview — flutter_map (OpenStreetMap, no API key needed)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 15,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _lat = point.latitude;
                        _lng = point.longitude;
                        _latCtrl.text = _lat.toStringAsFixed(6);
                        _lngCtrl.text = _lng.toStringAsFixed(6);
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fyp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
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
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Use GPS Location'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Latitude & Longitude Input Fields
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _latCtrl,
                    label: 'Latitude *',
                    prefixIcon: Icons.location_on_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() => _lat = parsed);
                        _mapController.move(LatLng(_lat, _lng), _mapController.camera.zoom);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Latitude required';
                      if (double.tryParse(v) == null) return 'Invalid lat';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _lngCtrl,
                    label: 'Longitude *',
                    prefixIcon: Icons.explore_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() => _lng = parsed);
                        _mapController.move(LatLng(_lat, _lng), _mapController.camera.zoom);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Longitude required';
                      if (double.tryParse(v) == null) return 'Invalid lng';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Paste Google Maps Link parser
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _mapsUrlCtrl,
                    label: 'Paste Google Maps Link / Coordinates',
                    prefixIcon: Icons.link_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _parseMapsInput(_mapsUrlCtrl.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  child: const Text('Parse'),
                ),
              ],
            ),
            const SizedBox(height: 24),


            // ── Upload Progress ──────────────────────────────────────────────
            Obx(() {
              if (!_hostelCtrl.isUploading.value) return const SizedBox.shrink();
              return Column(
                children: [
                  Text(
                      'Uploading images: ${_hostelCtrl.uploadProgress.value}%'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _hostelCtrl.uploadProgress.value / 100,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),

            // ── Submit Button ────────────────────────────────────────────────
            Obx(() => CustomButton(
                  text: _isEditing ? 'Save Changes' : 'Submit for Approval',
                  isLoading: _hostelCtrl.isLoading.value,
                  icon: _isEditing ? Icons.save_outlined : Icons.send_outlined,
                  onPressed: _submit,
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Section header with divider ────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String title;
  const _FormSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(height: 8),
      ],
    );
  }
}

// ── Image thumbnail with remove button ────────────────────────────────────
class _ImageThumb extends StatelessWidget {
  final Widget _image;
  final VoidCallback onRemove;

  const _ImageThumb._({required Widget image, required this.onRemove})
      : _image = image;

  factory _ImageThumb.network({required String url, required VoidCallback onRemove}) {
    return _ImageThumb._(
      image: Image.network(url, width: 90, height: 90, fit: BoxFit.cover),
      onRemove: onRemove,
    );
  }

  factory _ImageThumb.file({required File file, required VoidCallback onRemove}) {
    return _ImageThumb._(
      image: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _image,
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
