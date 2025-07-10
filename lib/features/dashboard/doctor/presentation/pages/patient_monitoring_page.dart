// =============================================================================
// Patient Monitoring Page
//
// Real-time patient monitoring interface for doctors
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/doctor_api_service.dart';
import '../../../../../features/auth/presentation/providers/user_provider.dart';
import '../widgets/patient_card.dart';

// Patient Monitoring State Management
class MonitoringState {
  final List<Map<String, dynamic>> activePatients;
  final Map<String, dynamic>? selectedPatient;
  final List<Map<String, dynamic>> bpmData;
  final bool isLoading;
  final bool isMonitoring;
  final String? error;

  const MonitoringState({
    this.activePatients = const [],
    this.selectedPatient,
    this.bpmData = const [],
    this.isLoading = false,
    this.isMonitoring = false,
    this.error,
  });

  MonitoringState copyWith({
    List<Map<String, dynamic>>? activePatients,
    Map<String, dynamic>? selectedPatient,
    List<Map<String, dynamic>>? bpmData,
    bool? isLoading,
    bool? isMonitoring,
    String? error,
  }) {
    return MonitoringState(
      activePatients: activePatients ?? this.activePatients,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      bpmData: bpmData ?? this.bpmData,
      isLoading: isLoading ?? this.isLoading,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: error,
    );
  }
}

class MonitoringNotifier extends StateNotifier<MonitoringState> {
  MonitoringNotifier() : super(const MonitoringState());

  final DoctorApiService _doctorApiService = DoctorApiService();

  Future<void> loadActivePatients(int doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _doctorApiService.getPatientsForDoctor(
        doctorId: doctorId,
        status: 'active',
      );

      // Extract patients array from response
      final patients = List<Map<String, dynamic>>.from(
        response['patients'] ?? [],
      );

      state = state.copyWith(activePatients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectPatient(Map<String, dynamic> patient) {
    state = state.copyWith(selectedPatient: patient, bpmData: []);
  }

  Future<void> startMonitoring(Map<String, dynamic> patient) async {
    state = state.copyWith(isMonitoring: true, selectedPatient: patient);

    // In a real app, this would establish a WebSocket connection
    // or start polling for real-time data
    // For now, we'll simulate it

    // This is where you'd integrate with actual monitoring hardware/API
    // Example: WebSocket connection to monitoring device
  }

  void stopMonitoring() {
    state = state.copyWith(isMonitoring: false, bpmData: []);
  }

  void addBpmReading(int bpm, int timestamp) {
    final newReading = {'time': timestamp, 'bpm': bpm};
    final updatedBpmData = [...state.bpmData, newReading];
    state = state.copyWith(bpmData: updatedBpmData);
  }

  Future<void> saveMonitoringRecord({
    required int patientId,
    required List<Map<String, dynamic>> bpmData,
    String? notes,
  }) async {
    try {
      await _doctorApiService.saveMonitoringRecord(
        patientId: patientId,
        bpmData: bpmData,
        notes: notes,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final monitoringProvider =
    StateNotifierProvider<MonitoringNotifier, MonitoringState>((ref) {
      return MonitoringNotifier();
    });

class PatientMonitoringPage extends ConsumerStatefulWidget {
  const PatientMonitoringPage({super.key});

  @override
  ConsumerState<PatientMonitoringPage> createState() =>
      _PatientMonitoringPageState();
}

class _PatientMonitoringPageState extends ConsumerState<PatientMonitoringPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivePatients();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadActivePatients() {
    final user = ref.read(userProvider);
    if (user != null) {
      ref.read(monitoringProvider.notifier).loadActivePatients(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(monitoringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Monitoring'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
        actions: [
          if (monitoringState.isMonitoring)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => _stopMonitoring(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivePatients,
          ),
        ],
      ),
      body:
          monitoringState.selectedPatient == null
              ? _buildPatientSelectionView(monitoringState)
              : _buildMonitoringView(monitoringState),
    );
  }

  Widget _buildPatientSelectionView(MonitoringState state) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Patient to Monitor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose from your active patients to start monitoring',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Patient List
        Expanded(
          child:
              state.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
                  )
                  : state.error != null
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
                          'Error loading patients',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActivePatients,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : state.activePatients.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active patients',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assign patients to start monitoring',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.activePatients.length,
                    itemBuilder: (context, index) {
                      final patient = state.activePatients[index];
                      return PatientCard(
                        patient: patient,
                        onTap: () => _selectPatient(patient),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildMonitoringView(MonitoringState state) {
    final patient = state.selectedPatient!;

    return Column(
      children: [
        // Patient Info Header
        Container(
          width: double.infinity,
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    () =>
                        ref.read(monitoringProvider.notifier).selectPatient({}),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF2E8B57).withOpacity(0.1),
                child: Text(
                  (patient['name']?.toString() ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2E8B57),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name']?.toString() ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      patient['email']?.toString() ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (!state.isMonitoring)
                ElevatedButton.icon(
                  onPressed: () => _startMonitoring(patient),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),

        // Monitoring Content
        Expanded(
          child:
              state.isMonitoring
                  ? _buildActiveMonitoringView(state)
                  : _buildPreMonitoringView(),
        ),
      ],
    );
  }

  Widget _buildPreMonitoringView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 64,
            color: Color(0xFF2E8B57),
          ),
          SizedBox(height: 16),
          Text(
            'Ready to Monitor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Press Start to begin monitoring this patient',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMonitoringView(MonitoringState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current BPM Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E8B57).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 48, color: Color(0xFF2E8B57)),
                const SizedBox(height: 12),
                Text(
                  state.bpmData.isNotEmpty
                      ? '${state.bpmData.last['bpm']} BPM'
                      : '-- BPM',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const Text(
                  'Real-time Heart Rate',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BPM History
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timeline, color: Color(0xFF2E8B57)),
                      const SizedBox(width: 8),
                      const Text(
                        'BPM Readings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${state.bpmData.length} readings',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        state.bpmData.isEmpty
                            ? const Center(
                              child: Text(
                                'No readings yet...\nMonitoring will start soon',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              itemCount: state.bpmData.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final reading =
                                    state.bpmData[state.bpmData.length -
                                        1 -
                                        index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  title: Text('${reading['bpm']} BPM'),
                                  trailing: Text(
                                    _formatTimestamp(reading['time']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes field
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Monitoring Notes',
              hintText: 'Add notes about this monitoring session...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _stopMonitoring(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      state.bpmData.isNotEmpty
                          ? () => _saveSession(state)
                          : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPatient(Map<String, dynamic> patient) {
    ref.read(monitoringProvider.notifier).selectPatient(patient);
  }

  void _startMonitoring(Map<String, dynamic> patient) {
    ref.read(monitoringProvider.notifier).startMonitoring(patient);

    // Simulate BPM readings for demo purposes
    _simulateBpmReadings();
  }

  void _stopMonitoring() {
    ref.read(monitoringProvider.notifier).stopMonitoring();
    _notesController.clear();
  }

  void _simulateBpmReadings() {
    // This is just for demo - in real app you'd connect to actual monitoring device
    Future.delayed(const Duration(seconds: 2), () {
      if (ref.read(monitoringProvider).isMonitoring) {
        final bpm = 70 + (DateTime.now().millisecondsSinceEpoch % 20);
        ref
            .read(monitoringProvider.notifier)
            .addBpmReading(bpm, DateTime.now().millisecondsSinceEpoch);
        _simulateBpmReadings(); // Continue simulation
      }
    });
  }

  Future<void> _saveSession(MonitoringState state) async {
    try {
      await ref
          .read(monitoringProvider.notifier)
          .saveMonitoringRecord(
            patientId: state.selectedPatient!['id'],
            bpmData: state.bpmData,
            notes:
                _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monitoring session saved successfully'),
            backgroundColor: Color(0xFF2E8B57),
          ),
        );
        _stopMonitoring();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
