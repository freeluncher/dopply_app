// =============================================================================
// Assign Patient Dialog
//
// Dialog for assigning patients to the doctor by email
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/doctor_api_service.dart';
import '../../../../../features/auth/presentation/providers/user_provider.dart';

class AssignPatientDialog extends ConsumerStatefulWidget {
  const AssignPatientDialog({super.key});

  @override
  ConsumerState<AssignPatientDialog> createState() =>
      _AssignPatientDialogState();
}

class _AssignPatientDialogState extends ConsumerState<AssignPatientDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Color(0xFF2E8B57)),
          SizedBox(width: 8),
          Text('Assign Patient'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Email field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Patient Email *',
                hintText: 'Enter patient email address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Note field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note about this assignment',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _assignPatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B57),
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _assignPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final doctorApiService = DoctorApiService();
      await doctorApiService.assignPatientByEmail(
        doctorId: user.id,
        patientEmail: _emailController.text.trim(),
        note:
            _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Patient ${_emailController.text.trim()} assigned successfully',
            ),
            backgroundColor: const Color(0xFF2E8B57),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Parse error message for better user experience
        String errorMessage = 'Failed to assign patient';

        if (e.toString().contains('Could not determine join condition') ||
            e.toString().contains('foreign keys linking')) {
          errorMessage = 'Server configuration error. Please contact support.';
        } else if (e.toString().contains('patient_id') ||
            e.toString().contains('Patient\' object has no attribute')) {
          errorMessage = 'Server database error. Please contact support.';
        } else if (e.toString().contains('patient not found') ||
            e.toString().toLowerCase().contains('email not found')) {
          errorMessage =
              'Patient with this email not found. Please check the email address.';
        } else if (e.toString().contains('already assigned')) {
          errorMessage = 'Patient is already assigned to this doctor.';
        } else if (e.toString().contains('unauthorized') ||
            e.toString().contains('403')) {
          errorMessage = 'You do not have permission to assign patients.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else {
          errorMessage = 'Failed to assign patient: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
