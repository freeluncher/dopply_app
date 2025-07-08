import 'package:flutter/material.dart';
import 'package:dopply_app/features/doctor/presentation/models/monitoring_patient.dart';
import 'package:dopply_app/app/theme.dart';

class PatientStatusUpdateDialog extends StatefulWidget {
  final MonitoringPatient patient;
  final Function(String status, String? notes) onStatusUpdate;

  const PatientStatusUpdateDialog({
    Key? key,
    required this.patient,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<PatientStatusUpdateDialog> createState() =>
      _PatientStatusUpdateDialogState();
}

class _PatientStatusUpdateDialogState extends State<PatientStatusUpdateDialog> {
  late String selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.patient.status;
    _notesController.text = widget.patient.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return AppColors.medicalGreen;
      case PatientStatus.inactive:
        return AppColors.medicalOrange;
      case PatientStatus.discharged:
        return AppColors.primaryBlue;
    }
  }

  IconData _getStatusIcon(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return Icons.play_circle;
      case PatientStatus.inactive:
        return Icons.pause_circle;
      case PatientStatus.discharged:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = widget.patient.availableStatusTransitions;
    final hasChanges =
        selectedStatus != widget.patient.status ||
        _notesController.text.trim() != (widget.patient.notes ?? '');

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_note,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Status Pasien',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.patient.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Status Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.medicalGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.patient.statusEnum),
                      color: _getStatusColor(widget.patient.statusEnum),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status Saat Ini: ${widget.patient.statusEnum.displayName}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Selection
              Text(
                'Pilih Status Baru:',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              ...availableStatuses.map((status) {
                final isSelected = selectedStatus == status.value;
                final isDisabled =
                    !widget.patient.canChangeStatus &&
                    status != widget.patient.statusEnum;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap:
                        isDisabled
                            ? null
                            : () {
                              setState(() {
                                selectedStatus = status.value;
                              });
                            },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? _getStatusColor(status).withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? _getStatusColor(status)
                                  : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: status.value,
                            groupValue: selectedStatus,
                            onChanged:
                                isDisabled
                                    ? null
                                    : (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedStatus = value;
                                        });
                                      }
                                    },
                            activeColor: _getStatusColor(status),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _getStatusIcon(status),
                            color:
                                isSelected
                                    ? _getStatusColor(status)
                                    : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.displayName,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? _getStatusColor(status)
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status.description,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // Notes Section
              Text(
                'Catatan (Opsional):',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan mengenai perubahan status...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading || !hasChanges
                  ? null
                  : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      await widget.onStatusUpdate(
                        selectedStatus,
                        _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengupdate status: $e'),
                            backgroundColor: AppColors.medicalRed,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.medicalWhite,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                  : const Text('Update Status'),
        ),
      ],
    );
  }
}
