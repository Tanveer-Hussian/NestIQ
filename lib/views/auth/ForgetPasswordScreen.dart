import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';

import '../shared Widgets/CustomButtons.dart';
import '../shared Widgets/CustomTextField.dart';
 
 
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final authCtrl = Get.find<AuthController>();
 
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_reset_outlined,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Enter your email address and we\'ll send you a password reset link.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: emailCtrl,
              label: 'Email Address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Obx(() => CustomButton(
                  text: 'Send Reset Link',
                  isLoading: authCtrl.isLoading.value,
                  icon: Icons.send_outlined,
                  onPressed: () {
                    if (emailCtrl.text.isNotEmpty) {
                      authCtrl.resetPassword(emailCtrl.text.trim());
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }
}
 