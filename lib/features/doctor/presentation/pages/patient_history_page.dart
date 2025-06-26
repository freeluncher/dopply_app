import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/doctor/data/services/record_api_service.dart';
import 'package:dopply_app/features/doctor/data/models/patient_history_record.dart';
import 'package:dopply_app/app/theme.dart';

/// Helper untuk menampilkan snackbar notifikasi/error dengan tema medical
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : isSuccess
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: AppColors.medicalWhite,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.medicalWhite,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          isError
              ? AppColors.medicalRed
              : isSuccess
              ? AppColors.medicalGreen
              : AppColors.primaryBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}

/// Halaman daftar riwayat monitoring pasien dengan medical theme
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<PatientHistoryRecord> allRecords = [];
  List<PatientHistoryRecord> filteredRecords = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'all'; // all, normal, tinggi, rendah

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Handle search dengan debouncing untuk performance
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _onSearch(_searchController.text);
    });
  }

  /// Mengambil data riwayat monitoring dari backend dengan error handling
  Future<void> _fetchRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final api = RecordApiService();
      final records = await api.fetchRecords();
      allRecords =
          records
              .map<PatientHistoryRecord>((r) => PatientHistoryRecord.fromMap(r))
              .toList();
      filteredRecords = allRecords;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat riwayat pasien: ${e.toString()}';
        });
        showAppSnackBar(
          context,
          'Gagal memuat data riwayat pasien',
          isError: true,
        );
      }
    }
  }

  /// Filter pencarian berdasarkan nama pasien, ID, dan klasifikasi
  void _onSearch(String query) {
    final searchQuery = query.toLowerCase();
    setState(() {
      filteredRecords =
          allRecords.where((record) {
            final matchesSearch =
                record.patientName.toLowerCase().contains(searchQuery) ||
                record.patientId.toLowerCase().contains(searchQuery) ||
                record.id.toString().contains(searchQuery);

            final matchesFilter = _matchesSelectedFilter(record);

            return matchesSearch && matchesFilter;
          }).toList();
    });
  }

  bool _matchesSelectedFilter(PatientHistoryRecord record) {
    if (selectedFilter == 'all') return true;

    final classification = record.classification?.toLowerCase() ?? '';
    switch (selectedFilter) {
      case 'normal':
        return classification.contains('normal');
      case 'tinggi':
        return classification.contains('tinggi') ||
            classification.contains('high');
      case 'rendah':
        return classification.contains('rendah') ||
            classification.contains('low');
      default:
        return true;
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _onSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCount = filteredRecords.length;
    final totalCount = allRecords.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRecords,
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.medicalWhite,
          child: CustomScrollView(
            slivers: [
              // Medical App Bar dengan gradient
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
                      'Riwayat Pasien',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.medicalWhite,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.medicalWhite,
                      size: 24,
                    ),
                    onPressed: _fetchRecords,
                    tooltip: 'Refresh Data',
                  ),
                  const SizedBox(width: 8),
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

                    // Filter Section
                    _buildFilterSection(),

                    const SizedBox(height: 20),

                    // Stats Header
                    _buildStatsHeader(filteredCount, totalCount),

                    const SizedBox(height: 16),

                    // History List atau Loading/Error State
                    _buildHistoryContent(),

                    // Bottom padding untuk FAB
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create new monitoring session
          context.push('/doctor/monitoring');
        },
        backgroundColor: AppColors.medicalGreen,
        foregroundColor: AppColors.medicalWhite,
        tooltip: 'Mulai monitoring baru',
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildSearchSection() {
    return MedicalCard(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Cari riwayat pasien',
          hintText: 'Masukkan nama pasien atau ID',
          prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
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
        enableSuggestions: true,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip('normal', 'Normal', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('tinggi', 'Tinggi', Icons.trending_up),
                const SizedBox(width: 8),
                _buildFilterChip('rendah', 'Rendah', Icons.trending_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => _applyFilter(value),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? AppColors.medicalWhite : AppColors.primaryBlue,
      ),
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.medicalWhite : AppColors.primaryBlue,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor:
          isSelected ? AppColors.primaryBlue : AppColors.medicalWhite,
      selectedColor: AppColors.primaryBlue,
      checkmarkColor: AppColors.medicalWhite,
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : AppColors.border,
        width: 1,
      ),
    );
  }

  Widget _buildStatsHeader(int filteredCount, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          filteredCount == totalCount
              ? 'Total $totalCount riwayat'
              : 'Menampilkan $filteredCount dari $totalCount riwayat',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (filteredCount != totalCount)
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearch('');
            },
            child: Text('Reset', style: AppTextStyles.textButton),
          ),
      ],
    );
  }

  Widget _buildHistoryContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredRecords.isEmpty) {
      return _buildEmptyState(_searchController.text.isNotEmpty);
    }

    return HistoryList(records: filteredRecords, onTap: _onHistoryTap);
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
            'Memuat riwayat pasien...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            errorMessage ?? 'Gagal memuat data riwayat',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchRecords,
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

  Widget _buildEmptyState(bool isSearching) {
    return MedicalCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.history,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Tidak Ada Hasil' : 'Belum Ada Riwayat',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Tidak ada riwayat yang sesuai dengan pencarian Anda'
                : 'Belum ada riwayat monitoring pasien tersimpan',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onHistoryTap(PatientHistoryRecord record) {
    context.push(
      '/doctor/patient-history/${record.id}',
      extra: record.toMap(), // Kirim map agar router bisa fromMap
    );
  }
}

/// Widget daftar riwayat dengan medical card styling dan responsive design
class HistoryList extends StatelessWidget {
  final List<PatientHistoryRecord> records;
  final void Function(PatientHistoryRecord) onTap;

  const HistoryList({super.key, required this.records, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid untuk tablet dan desktop
    if (screenWidth > 800) {
      return _buildGridLayout();
    }

    // List layout untuk mobile
    return _buildListLayout();
  }

  Widget _buildListLayout() {
    return Column(
      children: List.generate(records.length, (index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: HistoryCard(record: record, onTap: () => onTap(record)),
        );
      }),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return HistoryCard(
          record: record,
          onTap: () => onTap(record),
          isCompact: true,
        );
      },
    );
  }
}

/// Widget card individual untuk setiap riwayat dengan medical design
class HistoryCard extends StatelessWidget {
  final PatientHistoryRecord record;
  final VoidCallback onTap;
  final bool isCompact;

  const HistoryCard({
    super.key,
    required this.record,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: Semantics(
        label: 'Riwayat monitoring ${record.patientName}',
        hint: 'Ketuk untuk melihat detail riwayat',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // Medical icon dengan status indicator
                Container(
                  width: isCompact ? 40 : 56,
                  height: isCompact ? 40 : 56,
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(),
                    borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
                  ),
                  child: Icon(
                    Icons.monitor_heart,
                    color: AppColors.medicalWhite,
                    size: isCompact ? 20 : 28,
                  ),
                ),

                SizedBox(width: isCompact ? 12 : 16),

                // Record Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.patientName,
                        style: (isCompact
                                ? AppTextStyles.titleSmall
                                : AppTextStyles.titleMedium)
                            .copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${record.patientId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.classification ??
                              record.notes ??
                              'Tidak ada catatan',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (record.startTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(record.startTime!),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Record ID badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.medicalGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${record.id}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    // Return different gradients based on classification
    if (record.classification != null) {
      final classification = record.classification!.toLowerCase();
      if (classification.contains('normal')) {
        return AppColors.successGradient;
      } else if (classification.contains('tinggi') ||
          classification.contains('high')) {
        return const LinearGradient(
          colors: [AppColors.medicalRed, Color(0xFFD63384)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (classification.contains('rendah') ||
          classification.contains('low')) {
        return const LinearGradient(
          colors: [AppColors.medicalOrange, Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    return AppColors.primaryGradient;
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }
}
