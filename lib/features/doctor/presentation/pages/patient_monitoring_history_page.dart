import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/doctor/data/models/medical_record.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/medical_records_notifier.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/app/theme/medical_widgets.dart';

/// Halaman untuk melihat riwayat monitoring pasien tertentu (khusus dokter)
class PatientMonitoringHistoryPage extends ConsumerStatefulWidget {
  final DoctorPatient patient;

  const PatientMonitoringHistoryPage({super.key, required this.patient});

  @override
  ConsumerState<PatientMonitoringHistoryPage> createState() =>
      _PatientMonitoringHistoryPageState();
}

class _PatientMonitoringHistoryPageState
    extends ConsumerState<PatientMonitoringHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedDateFrom;
  String? _selectedDateTo;

  @override
  void initState() {
    super.initState();
    // Load data monitoring history untuk pasien ini
    Future.microtask(() {
      ref
          .read(patientMonitoringProvider.notifier)
          .loadPatientHistory(patientId: widget.patient.patientId);
    });

    // Setup scroll controller untuk pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(patientMonitoringProvider.notifier)
          .loadMore(widget.patient.patientId);
    }
  }

  void _applyDateFilter() {
    ref
        .read(patientMonitoringProvider.notifier)
        .loadPatientHistory(
          patientId: widget.patient.patientId,
          dateFrom: _selectedDateFrom,
          dateTo: _selectedDateTo,
        );
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    ref
        .read(patientMonitoringProvider.notifier)
        .loadPatientHistory(patientId: widget.patient.patientId);
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => DateFilterDialog(
            selectedDateFrom: _selectedDateFrom,
            selectedDateTo: _selectedDateTo,
            onApply: (dateFrom, dateTo) {
              setState(() {
                _selectedDateFrom = dateFrom;
                _selectedDateTo = dateTo;
              });
              _applyDateFilter();
            },
            onClear: _clearDateFilter,
          ),
    );
  }

  void _showRecordDetail(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => RecordDetailDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientMonitoringProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(patientMonitoringProvider.notifier)
                .loadPatientHistory(
                  patientId: widget.patient.patientId,
                  dateFrom: _selectedDateFrom,
                  dateTo: _selectedDateTo,
                );
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.medicalWhite,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Medical App Bar
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: FlexibleSpaceBar(
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Monitoring',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.medicalWhite,
                          ),
                        ),
                        Text(
                          widget.patient.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.medicalWhite.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.medicalWhite,
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: const Icon(
                        Icons.date_range,
                        color: AppColors.medicalWhite,
                        size: 28,
                      ),
                      onPressed: _showDateFilterDialog,
                      tooltip: 'Filter Tanggal',
                    ),
                  ),
                ],
              ),

              // Content dengan padding
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Patient Info Card
                    _buildPatientInfoCard(),

                    const SizedBox(height: 16),

                    // Date Filter (if active)
                    if (_selectedDateFrom != null ||
                        _selectedDateTo != null) ...[
                      _buildActiveDateFilter(),
                      const SizedBox(height: 16),
                    ],

                    // Stats/Summary
                    _buildSummaryStats(state),

                    const SizedBox(height: 16),

                    // Records List atau Loading/Error State
                    _buildRecordsContent(state),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return MedicalCard(
      backgroundColor: AppColors.medicalWhite,
      isElevated: true,
      child: Row(
        children: [
          // Patient Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.patient.name),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.medicalWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.patient.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.patient.age != null) ...[
                      Icon(
                        Icons.cake_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.patient.age} tahun',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (widget.patient.gender != null) ...[
                      Icon(
                        Icons.wc_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.patient.gender!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ID Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: ${widget.patient.patientId}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDateFilter() {
    return MedicalCard(
      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tanggal Aktif',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedDateFrom ?? 'Awal'} - ${_selectedDateTo ?? 'Akhir'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _clearDateFilter,
            child: Text(
              'Hapus Filter',
              style: AppTextStyles.textButton.copyWith(
                color: AppColors.medicalRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(PatientMonitoringState state) {
    final history = state.history;
    if (history == null) return const SizedBox.shrink();

    final records = history.records;
    final normalCount =
        records.where((r) => r.classification == 'normal').length;
    final abnormalCount =
        records.where((r) => r.classification == 'abnormal').length;
    final irregularCount =
        records.where((r) => r.classification == 'irregular').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.medical_information,
            title: 'Total',
            value: '${records.length}',
            subtitle: 'Rekam medis',
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Normal',
            value: '$normalCount',
            subtitle: 'Hasil normal',
            color: AppColors.medicalGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning,
            title: 'Perlu Perhatian',
            value: '${abnormalCount + irregularCount}',
            subtitle: 'Abnormal/Irregular',
            color: AppColors.medicalOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return MedicalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsContent(PatientMonitoringState state) {
    if (state.isLoading && state.history == null) {
      return _buildLoadingState();
    }

    if (state.error != null && state.history == null) {
      return _buildErrorState(state.error!);
    }

    if (state.history == null || state.history!.records.isEmpty) {
      return _buildEmptyState();
    }

    final records = state.history!.records;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Monitoring (${records.length})',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecordCard(
              record: record,
              onTap: () => _showRecordDetail(record),
              showPatientInfo:
                  false, // Tidak perlu show patient info karena sudah specific untuk 1 pasien
            ),
          ),
        ),
        if (state.isLoading && records.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return MedicalCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat riwayat monitoring...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return MedicalCard(
      backgroundColor: AppColors.medicalRedLight,
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.medicalRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.medicalRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(patientMonitoringProvider.notifier)
                  .loadPatientHistory(
                    patientId: widget.patient.patientId,
                    dateFrom: _selectedDateFrom,
                    dateTo: _selectedDateTo,
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return MedicalCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.history_outlined, color: AppColors.textTertiary, size: 64),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pasien ini belum memiliki riwayat monitoring dengan filter yang dipilih',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clearDateFilter,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// Widget RecordCard yang dapat dikustomisasi untuk show/hide patient info
class RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onTap;
  final bool showPatientInfo;

  const RecordCard({
    super.key,
    required this.record,
    required this.onTap,
    this.showPatientInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showPatientInfo)
                          Text(
                            record.patientName ?? 'Pasien #${record.patientId}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          )
                        else
                          Text(
                            'Monitoring #${record.id}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        Text(
                          record.formattedStartTime,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          record.source == 'clinic'
                              ? Icons.local_hospital
                              : Icons.home,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.sourceDisplayName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (record.averageBpm > 0) ...[
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppColors.medicalRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record.averageBpm.toStringAsFixed(0)} BPM',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                        if (record.durationInMinutes != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record.durationInMinutes}m',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            record.classificationStatus.displayName,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (record.classificationStatus) {
      case ClassificationStatus.normal:
        return AppColors.medicalGreen;
      case ClassificationStatus.abnormal:
        return AppColors.medicalRed;
      case ClassificationStatus.irregular:
        return AppColors.medicalOrange;
      case ClassificationStatus.unknown:
        return AppColors.textTertiary;
    }
  }
}

/// Dialog untuk filter tanggal
class DateFilterDialog extends StatefulWidget {
  final String? selectedDateFrom;
  final String? selectedDateTo;
  final Function(String?, String?) onApply;
  final VoidCallback onClear;

  const DateFilterDialog({
    super.key,
    this.selectedDateFrom,
    this.selectedDateTo,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<DateFilterDialog> {
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.selectedDateFrom;
    _dateTo = widget.selectedDateTo;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.date_range, color: AppColors.primaryBlue, size: 28),
          const SizedBox(width: 12),
          Text(
            'Filter Tanggal',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih rentang tanggal untuk memfilter riwayat monitoring',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Dari Tanggal',
                hintText: 'Pilih tanggal mulai',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              controller: TextEditingController(text: _dateFrom),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateFrom =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Sampai Tanggal',
                hintText: 'Pilih tanggal akhir',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              controller: TextEditingController(text: _dateTo),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateTo =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClear();
            Navigator.pop(context);
          },
          child: Text(
            'Hapus Semua',
            style: AppTextStyles.textButton.copyWith(
              color: AppColors.medicalRed,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: AppTextStyles.textButton.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_dateFrom, _dateTo);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.medicalWhite,
          ),
          child: Text('Terapkan', style: AppTextStyles.primaryButton),
        ),
      ],
    );
  }
}

/// Dialog untuk detail medical record (import dari medical_records_page.dart)
class RecordDetailDialog extends StatelessWidget {
  final MedicalRecord record;

  const RecordDetailDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.medical_information,
              color: _getStatusColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Rekam Medis',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'ID: ${record.id}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailSection('Informasi Pasien', [
                _DetailItem(
                  icon: Icons.person,
                  label: 'Nama Pasien',
                  value: record.patientName ?? 'Pasien #${record.patientId}',
                ),
                if (record.patientEmail != null)
                  _DetailItem(
                    icon: Icons.email,
                    label: 'Email',
                    value: record.patientEmail!,
                  ),
              ]),

              const SizedBox(height: 20),

              _buildDetailSection('Informasi Monitoring', [
                _DetailItem(
                  icon: Icons.access_time,
                  label: 'Waktu Mulai',
                  value: record.formattedStartTime,
                ),
                if (record.durationInMinutes != null)
                  _DetailItem(
                    icon: Icons.timer,
                    label: 'Durasi',
                    value: '${record.durationInMinutes} menit',
                  ),
                _DetailItem(
                  icon:
                      record.source == 'clinic'
                          ? Icons.local_hospital
                          : Icons.home,
                  label: 'Sumber',
                  value: record.sourceDisplayName,
                ),
                _DetailItem(
                  icon: Icons.analytics,
                  label: 'Klasifikasi',
                  value: record.classificationStatus.displayName,
                ),
                if (record.averageBpm > 0)
                  _DetailItem(
                    icon: Icons.favorite,
                    label: 'BPM Rata-rata',
                    value: '${record.averageBpm.toStringAsFixed(1)} BPM',
                  ),
              ]),

              if (record.notes != null) ...[
                const SizedBox(height: 20),
                _buildDetailSection('Catatan', [
                  _DetailItem(
                    icon: Icons.note,
                    label: 'Catatan Medis',
                    value: record.notes!,
                    isMultiline: true,
                  ),
                ]),
              ],

              if (record.bpmData.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildDetailSection('Data BPM', [
                  _DetailItem(
                    icon: Icons.show_chart,
                    label: 'Jumlah Data Point',
                    value: '${record.bpmData.length} titik data',
                  ),
                  _DetailItem(
                    icon: Icons.trending_up,
                    label: 'Rentang BPM',
                    value: _getBpmRange(),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: Text('Tutup', style: AppTextStyles.textButton),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.medicalGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.map((item) => _buildDetailRow(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            item.isMultiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
        children: [
          Icon(item.icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (record.classificationStatus) {
      case ClassificationStatus.normal:
        return AppColors.medicalGreen;
      case ClassificationStatus.abnormal:
        return AppColors.medicalRed;
      case ClassificationStatus.irregular:
        return AppColors.medicalOrange;
      case ClassificationStatus.unknown:
        return AppColors.textTertiary;
    }
  }

  String _getBpmRange() {
    if (record.bpmData.isEmpty) return 'Tidak ada data';

    final bpmValues = record.bpmData.map((e) => e.bpm).toList();
    final min = bpmValues.reduce((a, b) => a < b ? a : b);
    final max = bpmValues.reduce((a, b) => a > b ? a : b);

    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} BPM';
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });
}
