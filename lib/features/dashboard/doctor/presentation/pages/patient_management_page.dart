// =============================================================================
// Patient Management Page
//
// View and manage patients assigned to the doctor
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/doctor_dashboard_providers.dart';
import '../../../../../features/auth/presentation/providers/user_provider.dart';
import '../widgets/patient_card.dart';
import '../widgets/assign_patient_dialog.dart';

class PatientManagementPage extends ConsumerStatefulWidget {
  const PatientManagementPage({super.key});

  @override
  ConsumerState<PatientManagementPage> createState() =>
      _PatientManagementPageState();
}

class _PatientManagementPageState extends ConsumerState<PatientManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load patients when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPatients() {
    // Get doctor ID from user provider
    final user = ref.read(userProvider);
    if (user != null) {
      ref
          .read(doctorPatientsProvider.notifier)
          .loadPatients(user.id.toString());
    }
  }

  List<Map<String, dynamic>> _getFilteredPatients(
    List<Map<String, dynamic>> patients,
  ) {
    if (_searchQuery.isEmpty) return patients;

    return patients.where((patient) {
      final name = (patient['name'] ?? '').toString().toLowerCase();
      final email = (patient['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(doctorPatientsProvider);
    final filteredPatients = _getFilteredPatients(patientsState.patients);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAssignPatientDialog(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPatients),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E8B57)),
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
          ),

          // Patients List
          Expanded(
            child:
                patientsState.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E8B57),
                      ),
                    )
                    : patientsState.error != null
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
                            patientsState.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPatients,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : filteredPatients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No patients found matching "$_searchQuery"'
                                : 'No patients assigned yet',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Start by assigning patients to your care',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAssignPatientDialog(),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Assign Patient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E8B57),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async => _loadPatients(),
                      color: const Color(0xFF2E8B57),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return PatientCard(
                            patient: patient,
                            onTap: () => _navigateToPatientDetail(patient),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  void _showAssignPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => const AssignPatientDialog(),
    ).then((_) {
      // Refresh the patient list after assignment
      _loadPatients();
    });
  }

  void _navigateToPatientDetail(Map<String, dynamic> patient) {
    context.push('/doctor/patients/${patient['id']}', extra: patient);
  }
}
