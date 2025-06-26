import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/features/doctor/data/models/doctor_patient.dart';
import 'package:dopply_app/features/doctor/presentation/viewmodels/doctor_patients_notifier.dart';
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

/// Halaman daftar pasien yang ditangani dokter (CRUD relasi dokter-pasien)
/// Menggunakan Riverpod StateNotifier untuk state dan aksi CRUD.
class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Fetch data pasien saat halaman dibuka
    Future.microtask(
      () => ref.read(doctorPatientsProvider.notifier).fetchPatients(),
    );

    // Setup search controller listener untuk real-time search
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

  /// Filter pasien berdasarkan input pencarian
  void _onSearch(String query) {
    ref.read(doctorPatientsProvider.notifier).search(query);
  }

  /// Hapus pasien dengan konfirmasi dialog
  void _onDelete(DoctorPatient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => DeletePatientDialog(patient: patient),
    );
    if (confirm == true) {
      final success = await ref
          .read(doctorPatientsProvider.notifier)
          .deletePatient(patient);
      if (success) {
        showAppSnackBar(
          context,
          'Pasien ${patient.name} berhasil dihapus dari daftar Anda!',
          isSuccess: true,
        );
      } else {
        showAppSnackBar(
          context,
          'Gagal menghapus pasien ${patient.name}!',
          isError: true,
        );
      }
    }
  }

  /// Tambah pasien ke daftar dokter
  void _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddPatientDialog(),
    );
    if (result == true) {
      showAppSnackBar(
        context,
        'Pasien berhasil ditambahkan ke daftar Anda!',
        isSuccess: true,
      );
    }
  }

  /// Tampilkan detail pasien dalam dialog
  void _onDetail(DoctorPatient patient) {
    showDialog(
      context: context,
      builder: (_) => PatientDetailDialog(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorPatientsProvider);
    final filteredPatients =
        state.searchQuery.isEmpty
            ? state.patients
            : state.patients.where((p) {
              final name = p.name.toLowerCase();
              final email = p.email.toLowerCase();
              return name.contains(state.searchQuery.toLowerCase()) ||
                  email.contains(state.searchQuery.toLowerCase());
            }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(doctorPatientsProvider.notifier).fetchPatients();
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.medicalWhite,
          child: CustomScrollView(
            slivers: [
              // Medical App Bar dengan search
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
                      'Daftar Pasien',
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
                        Icons.person_add,
                        color: AppColors.medicalWhite,
                        size: 28,
                      ),
                      onPressed: _onAdd,
                      tooltip: 'Tambah Pasien',
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

                    const SizedBox(height: 20),

                    // Stats Header
                    _buildStatsHeader(
                      filteredPatients.length,
                      state.patients.length,
                    ),

                    const SizedBox(height: 16),

                    // Patient List atau Loading/Error State
                    _buildPatientContent(state, filteredPatients),
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
          labelText: 'Cari pasien',
          hintText: 'Masukkan nama atau email pasien',
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
        // Accessibility improvements
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: true,
      ),
    );
  }

  Widget _buildStatsHeader(int filteredCount, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          filteredCount == totalCount
              ? 'Total $totalCount pasien'
              : 'Menampilkan $filteredCount dari $totalCount pasien',
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

  Widget _buildPatientContent(state, List<DoctorPatient> filteredPatients) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (filteredPatients.isEmpty) {
      return _buildEmptyState(state.searchQuery.isNotEmpty);
    }

    return PatientList(
      patients: filteredPatients,
      onDetail: _onDetail,
      onDelete: _onDelete,
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
            'Memuat daftar pasien...',
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
              ref.read(doctorPatientsProvider.notifier).fetchPatients();
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

  Widget _buildEmptyState(bool isSearching) {
    return MedicalCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Tidak Ada Hasil' : 'Belum Ada Pasien',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Tidak ada pasien yang sesuai dengan pencarian Anda'
                : 'Tambahkan pasien pertama Anda untuk memulai monitoring',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Pasien'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget daftar pasien dengan medical card styling dan responsive design
class PatientList extends StatelessWidget {
  final List<DoctorPatient> patients;
  final void Function(DoctorPatient) onDetail;
  final void Function(DoctorPatient) onDelete;

  const PatientList({
    super.key,
    required this.patients,
    required this.onDetail,
    required this.onDelete,
  });

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
      children: List.generate(patients.length, (index) {
        final patient = patients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PatientCard(
            patient: patient,
            onTap: () => onDetail(patient),
            onDelete: () => onDelete(patient),
          ),
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
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientCard(
          patient: patient,
          onTap: () => onDetail(patient),
          onDelete: () => onDelete(patient),
          isCompact: true,
        );
      },
    );
  }
}

/// Widget card individual untuk setiap pasien dengan responsive design
class PatientCard extends StatelessWidget {
  final DoctorPatient patient;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isCompact;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: Semantics(
        label: 'Card pasien ${patient.name}',
        hint: 'Ketuk untuk melihat detail, atau gunakan tombol aksi',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // Avatar dengan initial
                Semantics(
                  label: 'Avatar ${patient.name}',
                  child: Container(
                    width: isCompact ? 40 : 56,
                    height: isCompact ? 40 : 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(patient.name),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.medicalWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: isCompact ? 12 : 16),

                // Patient Info
                Expanded(
                  child: Semantics(
                    label: 'Informasi pasien',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: (isCompact
                                  ? AppTextStyles.titleSmall
                                  : AppTextStyles.titleMedium)
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isCompact && patient.birthDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(patient.birthDate!),
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
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Detail pasien ${patient.name}',
                      hint: 'Ketuk untuk melihat informasi lengkap pasien',
                      child: IconButton(
                        onPressed: onTap,
                        icon: Icon(
                          Icons.info_outline,
                          color: AppColors.primaryBlue,
                          size: isCompact ? 20 : 24,
                        ),
                        tooltip: 'Detail Pasien',
                      ),
                    ),
                    Semantics(
                      label: 'Hapus pasien ${patient.name}',
                      hint: 'Ketuk untuk menghapus pasien dari daftar Anda',
                      child: IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.medicalRed,
                          size: isCompact ? 20 : 24,
                        ),
                        tooltip: 'Hapus Pasien',
                      ),
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

/// Dialog konfirmasi hapus pasien dengan tema medical
class DeletePatientDialog extends StatelessWidget {
  final DoctorPatient patient;

  const DeletePatientDialog({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.medicalOrange, size: 28),
          const SizedBox(width: 12),
          Text(
            'Hapus Pasien',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda yakin ingin menghapus pasien ini dari daftar Anda?',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.medicalGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patient.name),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.medicalWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        patient.email,
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
          const SizedBox(height: 12),
          Text(
            'Tindakan ini tidak dapat dibatalkan.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.medicalRed,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Batal',
            style: AppTextStyles.textButton.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.medicalRed,
            foregroundColor: AppColors.medicalWhite,
          ),
          child: Text('Hapus', style: AppTextStyles.primaryButton),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// Dialog tambah pasien dengan tema medical dan UX yang lebih baik
class AddPatientDialog extends ConsumerStatefulWidget {
  const AddPatientDialog({super.key});
  @override
  ConsumerState<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends ConsumerState<AddPatientDialog> {
  final emailController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? backendError;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    noteController.dispose();
    super.dispose();
  }

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
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_add,
              color: AppColors.medicalWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Tambah Pasien',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan informasi pasien yang akan ditambahkan ke daftar Anda',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Pasien',
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note Field
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Tambahkan catatan tentang pasien...',
                    prefixIcon: Icon(
                      Icons.note_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),

                // Error Message
                if (backendError != null && backendError!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.medicalRedLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.medicalRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.medicalRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            backendError!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.medicalRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: Text(
            'Batal',
            style: AppTextStyles.textButton.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalGreen,
              foregroundColor: AppColors.medicalWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                isLoading
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.medicalWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menambahkan...',
                          style: AppTextStyles.primaryButton,
                        ),
                      ],
                    )
                    : Text('Tambah Pasien', style: AppTextStyles.primaryButton),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
        backendError = null;
      });

      final notifier = ref.read(doctorPatientsProvider.notifier);
      final success = await notifier.addPatientByEmail(
        email: emailController.text.trim(),
        note: noteController.text.isNotEmpty ? noteController.text : null,
        onError: (err) => setState(() => backendError = err),
      );

      setState(() => isLoading = false);

      if (success) {
        Navigator.pop(context, true);
      }
    }
  }
}

/// Dialog detail pasien dengan tema medical dan informasi lengkap
class PatientDetailDialog extends StatelessWidget {
  final DoctorPatient patient;

  const PatientDetailDialog({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                _getInitials(patient.name),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.medicalWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pasien',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  patient.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryBlue,
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
              _buildDetailSection('Informasi Pribadi', [
                _DetailItem(
                  icon: Icons.person_outline,
                  label: 'Nama Lengkap',
                  value: patient.name,
                ),
                _DetailItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: patient.email,
                ),
                _DetailItem(
                  icon: Icons.cake_outlined,
                  label: 'Tanggal Lahir',
                  value:
                      patient.birthDate != null
                          ? _formatDate(patient.birthDate!)
                          : 'Tidak tersedia',
                ),
                _DetailItem(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: patient.address ?? 'Tidak tersedia',
                ),
              ]),

              const SizedBox(height: 20),

              _buildDetailSection('Informasi Medis', [
                _DetailItem(
                  icon: Icons.medical_information_outlined,
                  label: 'Catatan Medis',
                  value: patient.medicalNote ?? 'Tidak ada catatan',
                  isMultiline: true,
                ),
              ]),
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

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
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
    } catch (e) {
      return dateStr;
    }
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
