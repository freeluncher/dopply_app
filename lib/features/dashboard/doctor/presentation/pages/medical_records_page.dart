// =============================================================================
// Medical Records Page
//
// Access and view patient medical records
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/doctor_api_service.dart';

// Medical Records State Management
class MedicalRecordsState {
  final List<Map<String, dynamic>> records;
  final bool isLoading;
  final String? error;

  const MedicalRecordsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  MedicalRecordsState copyWith({
    List<Map<String, dynamic>>? records,
    bool? isLoading,
    String? error,
  }) {
    return MedicalRecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MedicalRecordsNotifier extends StateNotifier<MedicalRecordsState> {
  MedicalRecordsNotifier() : super(const MedicalRecordsState());

  final DoctorApiService _doctorApiService = DoctorApiService();

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await _doctorApiService.getRecords();
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final medicalRecordsProvider =
    StateNotifierProvider<MedicalRecordsNotifier, MedicalRecordsState>((ref) {
      return MedicalRecordsNotifier();
    });

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterSource = 'all'; // all, clinic, self

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecords() {
    ref.read(medicalRecordsProvider.notifier).loadRecords();
  }

  List<Map<String, dynamic>> _getFilteredRecords(
    List<Map<String, dynamic>> records,
  ) {
    var filtered = records;

    // Filter by source
    if (_filterSource != 'all') {
      filtered =
          filtered
              .where(
                (record) =>
                    (record['source'] ?? '').toString().toLowerCase() ==
                    _filterSource,
              )
              .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((record) {
            final patientName =
                (record['patient_name'] ?? '').toString().toLowerCase();
            final classification =
                (record['classification'] ?? '').toString().toLowerCase();
            final notes = (record['notes'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();

            return patientName.contains(query) ||
                classification.contains(query) ||
                notes.contains(query);
          }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(medicalRecordsProvider);
    final filteredRecords = _getFilteredRecords(recordsState.records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search records by patient, classification, or notes...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF2E8B57),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),

                const SizedBox(height: 12),

                // Filter Chips
                Row(
                  children: [
                    const Text(
                      'Filter by: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Clinic', 'clinic'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Self-monitoring', 'self'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child:
                recordsState.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E8B57),
                      ),
                    )
                    : recordsState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading records',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recordsState.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadRecords,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : filteredRecords.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty || _filterSource != 'all'
                                ? Icons.search_off
                                : Icons.medical_information_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterSource != 'all'
                                ? 'No records found'
                                : 'No medical records yet',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty || _filterSource != 'all'
                                ? 'Try adjusting your search or filter'
                                : 'Medical records will appear here',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async => _loadRecords(),
                      color: const Color(0xFF2E8B57),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterSource == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterSource = value);
      },
      selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E8B57),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final startTime = record['start_time']?.toString() ?? '';
    final source = record['source']?.toString() ?? '';
    final classification = record['classification']?.toString() ?? '';
    final notes = record['notes']?.toString() ?? '';
    final bpmData = record['bpm_data'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    source == 'clinic'
                        ? Icons.local_hospital
                        : Icons.self_improvement,
                    color: const Color(0xFF2E8B57),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      source == 'clinic' ? 'Clinic Record' : 'Self-monitoring',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (classification.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getClassificationColor(
                          classification,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        classification.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getClassificationColor(classification),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and BPM info
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(startTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (bpmData.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${bpmData.length} BPM readings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              // Notes (if available)
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  notes,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getClassificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'normal':
        return const Color(0xFF2E8B57);
      case 'abnormal':
        return Colors.red;
      case 'irregular':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => RecordDetailsDialog(record: record),
    );
  }
}

// Record Details Dialog
class RecordDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> record;

  const RecordDetailsDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final bpmData = record['bpm_data'] as List? ?? [];
    final startTime = record['start_time']?.toString() ?? '';
    final endTime = record['end_time']?.toString() ?? '';
    final source = record['source']?.toString() ?? '';
    final classification = record['classification']?.toString() ?? '';
    final notes = record['notes']?.toString() ?? '';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            source == 'clinic' ? Icons.local_hospital : Icons.self_improvement,
            color: const Color(0xFF2E8B57),
          ),
          const SizedBox(width: 8),
          const Text('Record Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Source',
              source == 'clinic' ? 'Clinic' : 'Self-monitoring',
            ),
            _buildDetailRow('Start Time', _formatDateTime(startTime)),
            if (endTime.isNotEmpty)
              _buildDetailRow('End Time', _formatDateTime(endTime)),
            if (classification.isNotEmpty)
              _buildDetailRow('Classification', classification),
            _buildDetailRow('BPM Readings', '${bpmData.length} data points'),
            if (notes.isNotEmpty) _buildDetailRow('Notes', notes),

            if (bpmData.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'BPM Data:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        bpmData.take(10).map((data) {
                          final time = data['time']?.toString() ?? '';
                          final bpm = data['bpm']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Time: $time'),
                                Text('BPM: $bpm'),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              if (bpmData.length > 10)
                Text(
                  '... and ${bpmData.length - 10} more readings',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
