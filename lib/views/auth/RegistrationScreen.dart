// ─────────────────────────────────────────────────────────────────────────────
// FR-1.1 & FR-1.2: Registration screen for students and hostel owners.
// Hostel owners must upload the front side of their CNIC at registration.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _universityController = TextEditingController();

    bool _obscurePassword = true;
    String _selectedRole = AppConstants.roleStudent;

    // CNIC image (owners only)
    File? _cnicFile;
    bool _isUploadingCnic = false;

    final AuthController _authController = Get.find<AuthController>();
    final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
    final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  // ── Pick CNIC image ────────────────────────────────────────────────────────
  Future<void> _pickCnic(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _cnicFile = File(picked.path));
    }
  }

  void _showCnicPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Upload CNIC (Front Side)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Get.back();
                        _pickCnic(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Get.back();
                        _pickCnic(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Register handler ───────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Validate CNIC for owners
    if (_selectedRole == AppConstants.roleOwner && _cnicFile == null) {
      Get.snackbar(
        'CNIC Required',
        'Please upload the front side of your CNIC to register as a hostel owner.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.warning_outlined, color: Colors.white),
      );
      return;
    }

    // Upload CNIC to Cloudinary if selected
    String? cnicUrl;
    if (_cnicFile != null) {
      setState(() => _isUploadingCnic = true);
      try {
        cnicUrl = await _cloudinaryService.uploadImage(
          _cnicFile!,
          folder: 'cnic',
        );
      } catch (e) {
        setState(() => _isUploadingCnic = false);
        Get.snackbar(
          'Upload Failed',
          'Could not upload CNIC image. Please try again.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      setState(() => _isUploadingCnic = false);
    }

    await _authController.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim(),
      university: _selectedRole == AppConstants.roleStudent
          ? _universityController.text.trim()
          : null,
      cnicImageUrl: cnicUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _selectedRole == AppConstants.roleOwner;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Role Selector ────────────────────────────────────────────
                Text(
                  'I am a:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.school_outlined,
                        label: 'Student',
                        isSelected: _selectedRole == AppConstants.roleStudent,
                        onTap: () => setState(
                            () => _selectedRole = AppConstants.roleStudent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.business_outlined,
                        label: 'Hostel Owner',
                        isSelected: isOwner,
                        onTap: () => setState(
                            () => _selectedRole = AppConstants.roleOwner),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Full Name ────────────────────────────────────────────────
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Email ────────────────────────────────────────────────────
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!GetUtils.isEmail(v)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Phone ────────────────────────────────────────────────────
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),

                // ── University (students only) ────────────────────────────────
                if (!isOwner) ...[
                  CustomTextField(
                    controller: _universityController,
                    label: 'University / Institution',
                    prefixIcon: Icons.account_balance_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'University is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── CNIC Upload (owners only) ─────────────────────────────────
                if (isOwner) ...[
                  _CnicUploadCard(
                    cnicFile: _cnicFile,
                    isUploading: _isUploadingCnic,
                    onTap: _showCnicPicker,
                    onRemove: () => setState(() => _cnicFile = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Password ─────────────────────────────────────────────────
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ─────────────────────────────────────────
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Error Message ─────────────────────────────────────────────
                Obx(() {
                  if (_authController.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _authController.errorMessage.value,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),

                // ── Register Button ───────────────────────────────────────────
                Obx(() => CustomButton(
                      text: _isUploadingCnic
                          ? 'Uploading CNIC…'
                          : 'Create Account',
                      isLoading: _authController.isLoading.value || _isUploadingCnic,
                      onPressed: _handleRegister,
                    )),
                const SizedBox(height: 16),

                // ── Login Link ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── CNIC Upload Card ──────────────────────────────────────────────────────────
class _CnicUploadCard extends StatelessWidget {
  final File? cnicFile;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _CnicUploadCard({
    required this.cnicFile,
    required this.isUploading,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.credit_card_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'CNIC — Front Side',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Required',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cnicFile != null
                  ? Colors.transparent
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cnicFile != null ? AppColors.primary : AppColors.divider,
                width: cnicFile != null ? 2 : 1.5,
                style: cnicFile != null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : cnicFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(cnicFile!, fit: BoxFit.cover),
                          ),
                          // Remove / change button overlay
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                _iconBtn(
                                  Icons.edit_outlined,
                                  AppColors.primary,
                                  onTap,
                                ),
                                const SizedBox(width: 6),
                                _iconBtn(
                                  Icons.delete_outline,
                                  AppColors.error,
                                  onRemove,
                                ),
                              ],
                            ),
                          ),
                          // "Verified" watermark at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.85),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(13),
                                  bottomRight: Radius.circular(13),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text('CNIC image selected',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.upload_outlined,
                                color: AppColors.primary, size: 30),
                          ),
                          const SizedBox(height: 10),
                          Text('Tap to upload CNIC front',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Camera or Gallery',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This will be reviewed by our admin team for verification.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ── Source option tile ────────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Role selection card widget ─────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
