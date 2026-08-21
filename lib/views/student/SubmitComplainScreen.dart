// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/submit_complaint_screen.dart
// FR-7.1: Student submits a service complaint.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  // Arguments: HostelModel passed from HostelDetailSceen
  late final HostelModel _hostel = Get.arguments as HostelModel;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintCtrl = Get.find<ComplaintController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(Icons.report_problem_outlined,
                  size: 48, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                'Report an Issue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                _hostel.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Complaint title
              CustomTextField(
                controller: _titleController,
                label: 'Issue Title',
                hint: 'e.g. WiFi not working, Broken door lock',
                prefixIcon: Icons.title,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Detailed description
              TextFormField(
                controller: _descController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description',
                  hintText: 'Describe the issue in detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 20) return 'Please provide more details (min 20 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Obx(() => ElevatedButton.icon(
                onPressed: complaintCtrl.isLoading.value
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await complaintCtrl.submitComplaint(
                          hostelId: _hostel.id,
                          hostelName: _hostel.name,
                          ownerId: _hostel.ownerId,
                          title: _titleController.text.trim(),
                          description: _descController.text.trim(),
                        );
                        if (ok) Get.back();
                      },
                icon: complaintCtrl.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(complaintCtrl.isLoading.value
                    ? 'Submitting...'
                    : 'Submit Complaint'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
