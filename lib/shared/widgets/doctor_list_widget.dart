import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/app/theme.dart';
import 'package:dopply_app/shared/services/doctor_list_service.dart';

/// State provider untuk doctor list
class DoctorListState {
  final bool isLoading;
  final String? error;
  final List<Doctor> doctors;
  final Map<String, dynamic>? pagination;
  final String searchQuery;
  final String? selectedSpecialization;

  const DoctorListState({
    this.isLoading = false,
    this.error,
    this.doctors = const [],
    this.pagination,
    this.searchQuery = '',
    this.selectedSpecialization,
  });

  DoctorListState copyWith({
    bool? isLoading,
    String? error,
    List<Doctor>? doctors,
    Map<String, dynamic>? pagination,
    String? searchQuery,
    String? selectedSpecialization,
  }) {
    return DoctorListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      doctors: doctors ?? this.doctors,
      pagination: pagination ?? this.pagination,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialization:
          selectedSpecialization ?? this.selectedSpecialization,
    );
  }
}

/// ViewModel untuk menangani doctor list
class DoctorListViewModel extends StateNotifier<DoctorListState> {
  final DoctorListService _doctorService;

  DoctorListViewModel({DoctorListService? doctorService})
    : _doctorService = doctorService ?? DoctorListService(),
      super(const DoctorListState());

  /// Load daftar dokter
  Future<void> loadDoctors({int page = 1, bool append = false}) async {
    if (!append) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await _doctorService.getDoctors(
        page: page,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        specialization: state.selectedSpecialization,
        isValid: true, // Hanya tampilkan dokter yang sudah divalidasi
      );

      if (result != null && result['success'] == true) {
        final newDoctors = result['doctors'] as List<Doctor>;
        final pagination = result['pagination'] as Map<String, dynamic>?;

        state = state.copyWith(
          isLoading: false,
          doctors: append ? [...state.doctors, ...newDoctors] : newDoctors,
          pagination: pagination,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result?['message'] ?? 'Gagal memuat daftar dokter',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat daftar dokter: ${e.toString()}',
      );
    }
  }

  /// Search dokter berdasarkan nama atau spesialisasi
  void searchDoctors(String query) {
    state = state.copyWith(searchQuery: query);
    loadDoctors(); // Reload dengan query baru
  }

  /// Filter berdasarkan spesialisasi
  void filterBySpecialization(String? specialization) {
    state = state.copyWith(selectedSpecialization: specialization);
    loadDoctors(); // Reload dengan filter baru
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Assign pasien ke dokter
  Future<bool> assignPatientToDoctor(int patientId, int doctorId) async {
    try {
      final result = await _doctorService.assignPatientToDoctor(
        patientId,
        doctorId,
      );
      return result != null && result['success'] == true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal assign dokter: ${e.toString()}');
      return false;
    }
  }
}

/// Provider untuk DoctorListViewModel
final doctorListProvider =
    StateNotifierProvider<DoctorListViewModel, DoctorListState>(
      (ref) => DoctorListViewModel(),
    );

/// Widget untuk menampilkan daftar dokter
class DoctorListWidget extends ConsumerStatefulWidget {
  final bool allowSelection;
  final Function(Doctor)? onDoctorSelected;
  final Function(Doctor)? onDoctorTapped;

  const DoctorListWidget({
    Key? key,
    this.allowSelection = false,
    this.onDoctorSelected,
    this.onDoctorTapped,
  }) : super(key: key);

  @override
  ConsumerState<DoctorListWidget> createState() => _DoctorListWidgetState();
}

class _DoctorListWidgetState extends ConsumerState<DoctorListWidget> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorListProvider.notifier).loadDoctors();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = ref.read(doctorListProvider);
      final pagination = state.pagination;

      if (pagination != null) {
        final currentPage = pagination['current_page'] ?? 1;
        final totalPages = pagination['total_pages'] ?? 1;

        if (currentPage < totalPages && !state.isLoading) {
          ref
              .read(doctorListProvider.notifier)
              .loadDoctors(page: currentPage + 1, append: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorListProvider);

    return Column(
      children: [
        // Search dan Filter
        _buildSearchAndFilter(),

        // Doctor List
        Expanded(child: _buildDoctorList(state)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari dokter...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(doctorListProvider.notifier)
                              .searchDoctors('');
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  ref.read(doctorListProvider.notifier).searchDoctors(value);
                }
              });
            },
          ),

          const SizedBox(height: 12),

          // Specialization filter
          _buildSpecializationFilter(),
        ],
      ),
    );
  }

  Widget _buildSpecializationFilter() {
    const specializations = [
      'Semua',
      'Kardiologi',
      'Neurologi',
      'Pediatri',
      'Ortopedi',
      'Dermatologi',
      'Ginekologi',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specializations.length,
        itemBuilder: (context, index) {
          final specialization = specializations[index];
          final state = ref.watch(doctorListProvider);
          final isSelected =
              (index == 0 && state.selectedSpecialization == null) ||
              state.selectedSpecialization == specialization;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(specialization),
              selected: isSelected,
              onSelected: (selected) {
                final filterValue = index == 0 ? null : specialization;
                ref
                    .read(doctorListProvider.notifier)
                    .filterBySpecialization(filterValue);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorList(DoctorListState state) {
    if (state.isLoading && state.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.medicalRed),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.medicalRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(doctorListProvider.notifier).loadDoctors();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Tidak ada dokter ditemukan',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.doctors.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.doctors.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final doctor = state.doctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.medicalGray,
          backgroundImage:
              doctor.photoUrl != null ? NetworkImage(doctor.photoUrl!) : null,
          child:
              doctor.photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
        ),
        title: Text(doctor.name, style: AppTextStyles.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor.specialization != null)
              Text(
                doctor.specialization!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            if (doctor.workLocation != null)
              Text(
                doctor.workLocation!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (doctor.rating != null)
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: AppColors.medicalOrange),
                  const SizedBox(width: 4),
                  Text(
                    doctor.rating!.toStringAsFixed(1),
                    style: AppTextStyles.bodySmall,
                  ),
                  if (doctor.patientCount != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${doctor.patientCount} pasien',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        trailing:
            widget.allowSelection
                ? IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => widget.onDoctorSelected?.call(doctor),
                )
                : const Icon(Icons.chevron_right),
        onTap: () => widget.onDoctorTapped?.call(doctor),
      ),
    );
  }
}
