import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/patient.dart';
import 'package:dopply_app/services/patient_service.dart';
import 'package:dopply_app/core/storage.dart';
import 'package:dopply_app/core/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMsg;

  // Biodata fields
  int? id;
  int? userId;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  DateTime? hpht;
  DateTime? birthDate;
  TextEditingController addressController = TextEditingController();
  TextEditingController medicalNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    medicalNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final userJson = await StorageService.getUserData();
    int? patientId;
    if (userJson != null && userJson.isNotEmpty) {
      final userMap = jsonDecode(userJson);
      patientId = userMap['id'];
      userId = userMap['user_id'] ?? userMap['id'];
    }
    if (patientId != null) {
      final patientService = ref.read(patientServiceProvider);
      final patient = await patientService.getPatientProfile(patientId);
      if (patient != null) {
        setState(() {
          id = patient.id;
          userId = patient.userId ?? patient.id;
          nameController.text = patient.name;
          emailController.text = patient.email;
          hpht = patient.hpht;
          birthDate = patient.birthDate;
          addressController.text = patient.address ?? '';
          medicalNoteController.text = patient.medicalNote ?? '';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final token = await StorageService.getToken();
      final url = 'https://dopply.my.id/api/v1/patient/$id';
      final body = jsonEncode({
        'user_id': userId,
        'name': nameController.text,
        'email': emailController.text,
        'hpht': hpht?.toIso8601String(),
        'birth_date': birthDate?.toIso8601String(),
        'address': addressController.text,
        'medical_note': medicalNoteController.text,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final respJson = jsonDecode(response.body);
      if (response.statusCode == 200 && respJson['status'] == 'success') {
        // Update local storage
        await StorageService.saveUserData(jsonEncode(respJson['data']));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biodata berhasil diperbarui!'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          // Redirect to dashboard according to role
          final role = await StorageService.getUserRole();
          if (role == 'doctor') {
            context.go('/doctor_dashboard');
          } else {
            context.go('/patient_dashboard');
          }
        }
      } else {
        setState(() {
          _errorMsg = respJson['message'] ?? 'Gagal update biodata';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Biodata'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback: redirect to dashboard sesuai role
              StorageService.getUserRole().then((role) {
                if (role == 'doctor') {
                  context.go('/doctor_dashboard');
                } else {
                  context.go('/patient_dashboard');
                }
              });
            }
          },
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 0,
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Biodata Pasien', style: AppTheme.heading2),
                              const SizedBox(height: 4),
                              Text(
                                'Lengkapi informasi biodata Anda',
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Error Message
                if (_errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Fields Card
                Card(
                  elevation: 0,
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Pribadi', style: AppTheme.heading3),
                        const SizedBox(height: 16),

                        // Name Field
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Masukkan nama lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Nama wajib diisi'
                                      : null,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Masukkan alamat email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(v)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // HPHT Field
                        _DatePickerField(
                          label: 'Hari Pertama Haid Terakhir (HPHT)',
                          value: hpht,
                          onChanged: (date) => setState(() => hpht = date),
                          icon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Birth Date Field
                        _DatePickerField(
                          label: 'Tanggal Lahir',
                          value: birthDate,
                          onChanged: (date) => setState(() => birthDate = date),
                          icon: Icons.cake_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Address Field
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Alamat',
                            hintText: 'Masukkan alamat lengkap',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Medical Note Field
                        TextFormField(
                          controller: medicalNoteController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Medis',
                            hintText: 'Masukkan catatan medis (opsional)',
                            prefixIcon: Icon(
                              Icons.medical_information_outlined,
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text('Simpan Biodata', style: AppTheme.button),
                              ],
                            ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final IconData icon;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: AppTheme.surfaceColor,
                  onSurface: AppTheme.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon:
              value != null
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onChanged(null),
                  )
                  : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value != null ? _formatDate(value!) : 'Pilih tanggal',
          style: TextStyle(
            color:
                value != null ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
