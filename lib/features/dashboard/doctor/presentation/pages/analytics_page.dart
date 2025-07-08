// =============================================================================
// Analytics Page
//
// Reports and insights for doctor dashboard
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/doctor_api_service.dart';
import '../pages/doctor_dashboard.dart';

// Analytics State Management
class AnalyticsState {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> recentRecords;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.stats = const {},
    this.recentRecords = const [],
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? recentRecords,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      stats: stats ?? this.stats,
      recentRecords: recentRecords ?? this.recentRecords,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState());

  final DoctorApiService _doctorApiService = DoctorApiService();

  Future<void> loadAnalytics(int doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load analytics data using doctor statistics endpoint
      final statsResponse = await _doctorApiService.getDoctorStatistics(
        doctorId: doctorId,
      );

      // Load recent records
      final recordsData = await _doctorApiService.getRecords(
        doctorId: doctorId,
      );

      // Get recent records (last 10)
      final recentRecords = recordsData.take(10).toList();

      state = state.copyWith(
        stats: statsResponse,
        recentRecords: recentRecords,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      return AnalyticsNotifier();
    });

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _selectedPeriod = 'month'; // today, week, month, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  void _loadAnalytics() {
    final user = ref.read(dashboardUserProvider);
    if (user != null) {
      ref.read(analyticsProvider.notifier).loadAnalytics(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body:
          analyticsState.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
              )
              : analyticsState.error != null
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
                      'Error loading analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analyticsState.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalytics,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async => _loadAnalytics(),
                color: const Color(0xFF2E8B57),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector
                      _buildPeriodSelector(),

                      const SizedBox(height: 20),

                      // Overview Stats
                      _buildOverviewStats(analyticsState.stats),

                      const SizedBox(height: 20),

                      // Classification Chart
                      _buildClassificationChart(analyticsState.stats),

                      const SizedBox(height: 20),

                      // Record Activity
                      _buildRecordActivity(analyticsState.stats),

                      const SizedBox(height: 20),

                      // Recent Records
                      _buildRecentRecords(analyticsState.recentRecords),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Analytics Period',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Today', 'today'),
                const SizedBox(width: 8),
                _buildPeriodChip('This Week', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip('This Month', 'month'),
                const SizedBox(width: 8),
                _buildPeriodChip('All Time', 'all'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = value);
      },
      selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E8B57),
    );
  }

  Widget _buildOverviewStats(Map<String, dynamic> stats) {
    final recordCount = _getRecordCountForPeriod(stats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text(
                'Overview Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Records',
                recordCount.toString(),
                Icons.description,
                const Color(0xFF2E8B57),
              ),
              _buildStatCard(
                'Patients',
                '${(stats['patients'] as Map<String, dynamic>?)?['total'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Active Patients',
                '${(stats['patients'] as Map<String, dynamic>?)?['active'] ?? 0}',
                Icons.person_add,
                Colors.green,
              ),
              _buildStatCard(
                'Normal Rate',
                '${_getNormalRate(stats)}%',
                Icons.check_circle,
                const Color(0xFF2E8B57),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationChart(Map<String, dynamic> stats) {
    final classifications =
        stats['classifications'] as Map<String, dynamic>? ?? {};
    final normal = classifications['normal'] ?? 0;
    final abnormal = classifications['abnormal'] ?? 0;
    final irregular = classifications['irregular'] ?? 0;
    final total = normal + abnormal + irregular;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text(
                'Classification Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0) ...[
            _buildClassificationBar(
              'Normal',
              normal,
              total,
              const Color(0xFF2E8B57),
            ),
            const SizedBox(height: 8),
            _buildClassificationBar('Abnormal', abnormal, total, Colors.red),
            const SizedBox(height: 8),
            _buildClassificationBar(
              'Irregular',
              irregular,
              total,
              Colors.orange,
            ),
          ] else ...[
            const Center(
              child: Text(
                'No classification data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassificationBar(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: total > 0 ? count / total : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Text(
                '$count ($percentage%)',
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordActivity(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Row(
            children: [
              Icon(Icons.timeline, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text(
                'Record Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Today',
                  '${stats['todayRecords'] ?? 0}',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'This Week',
                  '${stats['weekRecords'] ?? 0}',
                  Icons.date_range,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'This Month',
                  '${stats['monthRecords'] ?? 0}',
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords(List<Map<String, dynamic>> records) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF2E8B57)),
              SizedBox(width: 8),
              Text(
                'Recent Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Center(
              child: Text(
                'No recent records available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                final startTime = record['start_time']?.toString() ?? '';
                final classification =
                    record['classification']?.toString() ?? 'Unknown';
                final source = record['source']?.toString() ?? '';

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    source == 'clinic'
                        ? Icons.local_hospital
                        : Icons.self_improvement,
                    color: const Color(0xFF2E8B57),
                    size: 20,
                  ),
                  title: Text(
                    classification.isNotEmpty
                        ? classification.toUpperCase()
                        : 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _getClassificationColor(classification),
                    ),
                  ),
                  subtitle: Text(
                    _formatDateTime(startTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getClassificationColor(
                        classification,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getClassificationColor(classification),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  int _getRecordCountForPeriod(Map<String, dynamic> stats) {
    final records = stats['records'] as Map<String, dynamic>? ?? {};
    switch (_selectedPeriod) {
      case 'today':
        // API doesn't provide today's records, use this_week as approximation
        return (records['this_week'] ?? 0) ~/ 7;
      case 'week':
        return records['this_week'] ?? 0;
      case 'month':
        return records['this_month'] ?? 0;
      case 'all':
      default:
        return records['total'] ?? 0;
    }
  }

  int _getNormalRate(Map<String, dynamic> stats) {
    final classifications =
        stats['classifications'] as Map<String, dynamic>? ?? {};
    final normal = classifications['normal'] ?? 0;
    final abnormal = classifications['abnormal'] ?? 0;
    final irregular = classifications['irregular'] ?? 0;
    final total = normal + abnormal + irregular;

    return total > 0 ? (normal / total * 100).round() : 0;
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
}
