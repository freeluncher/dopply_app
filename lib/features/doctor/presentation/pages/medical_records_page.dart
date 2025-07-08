import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/doctor/data/models/medical_record.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/medical_records_notifier.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/app/theme/medical_widgets.dart';

/// Halaman medical records - akses rekam medis pasien
class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  String? _selectedClassification;
  String? _selectedSource;
  String? _selectedDateFrom;
  String? _selectedDateTo;

  @override
  void initState() {
    super.initState();
    // Load data saat halaman dibuka
    Future.microtask(() {
      ref.read(medicalRecordsProvider.notifier).loadRecords(refresh: true);
    });

    // Setup search controller listener
    _searchController.addListener(_onSearchChanged);

    // Setup scroll controller untuk pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        ref.read(medicalRecordsProvider.notifier).searchRecords(query);
      } else {
        _applyFilters();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(medicalRecordsProvider.notifier).loadMoreRecords();
    }
  }

  void _applyFilters() {
    final filter = MedicalRecordFilter(
      classification: _selectedClassification,
      source: _selectedSource,
      dateFrom: _selectedDateFrom,
      dateTo: _selectedDateTo,
    );

    ref.read(medicalRecordsProvider.notifier).filterRecords(filter);
  }

  void _clearFilters() {
    setState(() {
      _selectedClassification = null;
      _selectedSource = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    _searchController.clear();
    ref.read(medicalRecordsProvider.notifier).clearFilter();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            selectedClassification: _selectedClassification,
            selectedSource: _selectedSource,
            selectedDateFrom: _selectedDateFrom,
            selectedDateTo: _selectedDateTo,
            onApply: (classification, source, dateFrom, dateTo) {
              setState(() {
                _selectedClassification = classification;
                _selectedSource = source;
                _selectedDateFrom = dateFrom;
                _selectedDateTo = dateTo;
              });
              _applyFilters();
            },
            onClear: _clearFilters,
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
    final state = ref.watch(medicalRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(medicalRecordsProvider.notifier).refreshRecords();
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.medicalWhite,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Medical App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: FlexibleSpaceBar(
                    title: Text(
                      'Rekam Medis',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.medicalWhite,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: AppColors.medicalWhite,
                        size: 28,
                      ),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filter Rekam Medis',
                    ),
                  ),
                ],
              ),

              // Content dengan padding
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search Section
                    _buildSearchSection(),

                    const SizedBox(height: 16),

                    // Active Filters (if any)
                    if (_hasActiveFilters()) ...[
                      _buildActiveFilters(),
                      const SizedBox(height: 16),
                    ],

                    // Stats Header
                    _buildStatsHeader(state),

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

  Widget _buildSearchSection() {
    return MedicalCard(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Cari rekam medis',
          hintText: 'Masukkan nama pasien atau email',
          prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                  : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
        ),
        textInputAction: TextInputAction.search,
        autocorrect: false,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedClassification != null ||
        _selectedSource != null ||
        _selectedDateFrom != null ||
        _selectedDateTo != null;
  }

  Widget _buildActiveFilters() {
    return MedicalCard(
      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Aktif',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Hapus Semua',
                  style: AppTextStyles.textButton.copyWith(
                    color: AppColors.medicalRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_selectedClassification != null)
                _buildFilterChip('Klasifikasi: $_selectedClassification'),
              if (_selectedSource != null)
                _buildFilterChip('Sumber: $_selectedSource'),
              if (_selectedDateFrom != null)
                _buildFilterChip('Dari: $_selectedDateFrom'),
              if (_selectedDateTo != null)
                _buildFilterChip('Sampai: $_selectedDateTo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue),
      ),
      backgroundColor: AppColors.medicalWhite,
      side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsHeader(MedicalRecordsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          state.isLoading && state.records.isEmpty
              ? 'Memuat...'
              : 'Total ${state.records.length} rekam medis',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (state.hasMore && state.records.isNotEmpty)
          Text(
            'Geser ke bawah untuk lebih banyak',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildRecordsContent(MedicalRecordsState state) {
    if (state.isLoading && state.records.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null && state.records.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.records.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Demo mode banner
        if (state.error != null && state.error!.contains('Demo Mode'))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.medicalOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.medicalOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: AppColors.medicalOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo Mode: Showing sample data while Medical Records API is under development',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.medicalOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...state.records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecordCard(
              record: record,
              onTap: () => _showRecordDetail(record),
            ),
          ),
        ),
        if (state.isLoading && state.records.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
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
            'Memuat rekam medis...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    IconData errorIcon;
    String errorTitle;
    String errorMessage;
    Color errorColor;
    bool showContactSupport = false;

    // Customize error message based on error type
    if (error.contains('temporarily unavailable') ||
        error.contains('under development')) {
      errorIcon = Icons.construction;
      errorTitle = 'Feature Under Development';
      errorMessage = error;
      errorColor = AppColors.medicalOrange;
      showContactSupport = false;
    } else if (error.contains('not found') ||
        error.contains('not be available')) {
      errorIcon = Icons.science;
      errorTitle = 'Coming Soon';
      errorMessage = error;
      errorColor = AppColors.primaryBlue;
      showContactSupport = false;
    } else if (error.contains('Access denied') ||
        error.contains('permissions')) {
      errorIcon = Icons.lock;
      errorTitle = 'Access Denied';
      errorMessage = error;
      errorColor = AppColors.medicalRed;
      showContactSupport = true;
    } else if (error.contains('Authentication failed') ||
        error.contains('login again')) {
      errorIcon = Icons.login;
      errorTitle = 'Authentication Required';
      errorMessage = error;
      errorColor = AppColors.medicalRed;
      showContactSupport = false;
    } else if (error.contains('Network') || error.contains('connection')) {
      errorIcon = Icons.wifi_off;
      errorTitle = 'Connection Problem';
      errorMessage = error;
      errorColor = AppColors.medicalOrange;
      showContactSupport = false;
    } else {
      errorIcon = Icons.error_outline;
      errorTitle = 'Something Went Wrong';
      errorMessage =
          error.length > 100
              ? 'An unexpected error occurred. Please try again.'
              : error;
      errorColor = AppColors.medicalRed;
      showContactSupport = true;
    }

    return MedicalCard(
      backgroundColor: errorColor.withOpacity(0.1),
      child: Column(
        children: [
          Icon(errorIcon, color: errorColor, size: 48),
          const SizedBox(height: 16),
          Text(
            errorTitle,
            style: AppTextStyles.titleMedium.copyWith(color: errorColor),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(medicalRecordsProvider.notifier).refreshRecords();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(backgroundColor: errorColor),
              ),
              if (showContactSupport) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    _showContactSupportDialog();
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                ),
              ],
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.support_agent, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Contact Support'),
              ],
            ),
            content: const Text(
              'If you continue to experience issues with Medical Records, please contact your system administrator or technical support team.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
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
          Icon(
            Icons.medical_information_outlined,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Rekam Medis',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada rekam medis yang tersedia dengan filter yang dipilih',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }
}

/// Widget card untuk menampilkan medical record
class RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onTap;

  const RecordCard({super.key, required this.record, required this.onTap});

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
                        Text(
                          record.patientName ?? 'Pasien #${record.patientId}',
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

/// Dialog untuk filter medical records
class FilterDialog extends StatefulWidget {
  final String? selectedClassification;
  final String? selectedSource;
  final String? selectedDateFrom;
  final String? selectedDateTo;
  final Function(String?, String?, String?, String?) onApply;
  final VoidCallback onClear;

  const FilterDialog({
    super.key,
    this.selectedClassification,
    this.selectedSource,
    this.selectedDateFrom,
    this.selectedDateTo,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _classification;
  String? _source;
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _classification = widget.selectedClassification;
    _source = widget.selectedSource;
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
          Icon(Icons.filter_list, color: AppColors.primaryBlue, size: 28),
          const SizedBox(width: 12),
          Text(
            'Filter Rekam Medis',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Classification filter
              Text(
                'Klasifikasi',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _classification,
                decoration: const InputDecoration(
                  hintText: 'Pilih klasifikasi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'abnormal', child: Text('Abnormal')),
                  DropdownMenuItem(
                    value: 'irregular',
                    child: Text('Tidak Teratur'),
                  ),
                ],
                onChanged: (value) => setState(() => _classification = value),
              ),

              const SizedBox(height: 16),

              // Source filter
              Text(
                'Sumber',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _source,
                decoration: const InputDecoration(
                  hintText: 'Pilih sumber',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'clinic', child: Text('Klinik')),
                  DropdownMenuItem(value: 'self', child: Text('Mandiri')),
                ],
                onChanged: (value) => setState(() => _source = value),
              ),

              const SizedBox(height: 16),

              // Date range
              Text(
                'Rentang Tanggal',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Dari tanggal',
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Sampai tanggal',
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
                  ),
                ],
              ),
            ],
          ),
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
            widget.onApply(_classification, _source, _dateFrom, _dateTo);
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

/// Dialog untuk detail medical record
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
          onPressed: () {
            Navigator.pop(context);
            // Navigate to patient monitoring history
            final patient = DoctorPatient(
              patientId: record.patientId,
              name: record.patientName ?? 'Pasien #${record.patientId}',
              email: record.patientEmail ?? '',
            );
            context.push('/doctor/patient-monitoring-history', extra: patient);
          },
          icon: const Icon(Icons.timeline),
          label: Text('Lihat Riwayat', style: AppTextStyles.textButton),
        ),
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
