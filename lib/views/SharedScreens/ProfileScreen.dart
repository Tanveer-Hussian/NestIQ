import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  final AuthController _authCtrl = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _universityCtrl;

  bool _isEditing = false;
  bool _isSaving = false;
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();

    final user = _authCtrl.currentUser.value;

    if (user != null) {
      _nameCtrl = TextEditingController(text: user.name);
      _phoneCtrl = TextEditingController(text: user.phone);
      _universityCtrl = TextEditingController(text: user.university ?? '');
    } else {
      _nameCtrl = TextEditingController();
      _phoneCtrl = TextEditingController();
      _universityCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  // ── Pick new profile photo ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      setState(() => _newProfileImage = File(file.path));
    }
  }

  // ── Save profile changes ───────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = _authCtrl.currentUser.value!.uid;
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      // Add university if student
      if (_authCtrl.isStudent) {
        updates['university'] = _universityCtrl.text.trim();
      }

      // Upload new profile image if selected
      if (_newProfileImage != null) {
        final imageUrl = await _cloudinaryService.uploadProfileImage(
            uid, _newProfileImage!);
        updates['profileImage'] = imageUrl;
      }

      await _authService.updateUserProfile(uid, updates);
      await _authCtrl.refreshUser(); // reload local state

      setState(() => _isEditing = false);
      Get.snackbar('Saved', 'Profile updated successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Could not update profile.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          // Edit / Save toggle button
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Obx(() {

        final user = _authCtrl.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Profile Avatar ─────────────────────────────────────────
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : (user.profileImage != null
                                ? NetworkImage(user.profileImage!) as ImageProvider
                                : null),
                        child: (_newProfileImage == null &&
                                user.profileImage == null)
                            ? Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 36,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      // Camera icon overlay in edit mode
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Editable Fields ────────────────────────────────────────
                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  readOnly: !_isEditing,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),

                // Email (always read-only – linked to Firebase Auth)
                CustomTextField(
                  controller: TextEditingController(text: user.email),
                  label: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  readOnly: true, // Cannot change email here
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  readOnly: !_isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // University field (students only)
                if (_authCtrl.isStudent) ...[
                  CustomTextField(
                    controller: _universityCtrl,
                    label: 'University',
                    prefixIcon: Icons.account_balance_outlined,
                    readOnly: !_isEditing,
                  ),
                  const SizedBox(height: 16),
                ],

                // Loading indicator while saving
                if (_isSaving) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],

                const SizedBox(height: 32),

                // ── Logout Button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Logout',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.toNamed(AppRoutes.login);
              _authCtrl.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

}
