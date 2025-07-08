// =============================================================================
// Admin Dashboard Providers
//
// Centralized state management for admin dashboard features including
// user management, system analytics, and doctor validation.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/api/user_api_service.dart';
import '../../../../../services/api/doctor_api_service.dart';
import '../../../../../services/api/monitoring_api_service.dart';

// System Statistics State
class SystemStats {
  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int pendingValidations;
  final int todaySessions;
  final int systemAlerts;
  final bool isLoading;
  final String? error;

  const SystemStats({
    this.totalUsers = 0,
    this.totalDoctors = 0,
    this.totalPatients = 0,
    this.pendingValidations = 0,
    this.todaySessions = 0,
    this.systemAlerts = 0,
    this.isLoading = false,
    this.error,
  });

  SystemStats copyWith({
    int? totalUsers,
    int? totalDoctors,
    int? totalPatients,
    int? pendingValidations,
    int? todaySessions,
    int? systemAlerts,
    bool? isLoading,
    String? error,
  }) {
    return SystemStats(
      totalUsers: totalUsers ?? this.totalUsers,
      totalDoctors: totalDoctors ?? this.totalDoctors,
      totalPatients: totalPatients ?? this.totalPatients,
      pendingValidations: pendingValidations ?? this.pendingValidations,
      todaySessions: todaySessions ?? this.todaySessions,
      systemAlerts: systemAlerts ?? this.systemAlerts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// System Statistics Notifier
class SystemStatsNotifier extends StateNotifier<SystemStats> {
  SystemStatsNotifier() : super(const SystemStats());

  final UserApiService _userApiService = UserApiService();
  final DoctorApiService _doctorApiService = DoctorApiService();
  final MonitoringApiService _monitoringApiService = MonitoringApiService();

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate loading system statistics
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - replace with actual API calls
      state = state.copyWith(
        totalUsers: 142,
        totalDoctors: 24,
        totalPatients: 118,
        pendingValidations: 8,
        todaySessions: 47,
        systemAlerts: 3,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }
}

// User Management State
class UserManagementState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> pendingDoctors;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.pendingDoctors = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? pendingDoctors,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      pendingDoctors: pendingDoctors ?? this.pendingDoctors,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// User Management Notifier
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  UserManagementNotifier() : super(const UserManagementState());

  final UserApiService _userApiService = UserApiService();
  final DoctorApiService _doctorApiService = DoctorApiService();

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Mock user data - replace with actual API call
      await Future.delayed(const Duration(milliseconds: 800));

      final mockUsers = [
        {
          'id': '1',
          'name': 'Dr. Sarah Johnson',
          'email': 'sarah.johnson@dopply.com',
          'role': 'doctor',
          'isValid': true,
          'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
          'registeredAt': DateTime.now().subtract(const Duration(days: 30)),
        },
        {
          'id': '2',
          'name': 'Maria Garcia',
          'email': 'maria.garcia@email.com',
          'role': 'patient',
          'isValid': true,
          'lastLogin': DateTime.now().subtract(const Duration(minutes: 30)),
          'registeredAt': DateTime.now().subtract(const Duration(days: 15)),
        },
        {
          'id': '3',
          'name': 'Dr. Michael Chen',
          'email': 'michael.chen@dopply.com',
          'role': 'doctor',
          'isValid': false,
          'lastLogin': null,
          'registeredAt': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'id': '4',
          'name': 'Emily Davis',
          'email': 'emily.davis@email.com',
          'role': 'patient',
          'isValid': true,
          'lastLogin': DateTime.now().subtract(const Duration(days: 1)),
          'registeredAt': DateTime.now().subtract(const Duration(days: 8)),
        },
      ];

      final mockPendingDoctors = [
        {
          'id': '3',
          'name': 'Dr. Michael Chen',
          'email': 'michael.chen@dopply.com',
          'specialization': 'Cardiology',
          'licenseNumber': 'MD-2024-001',
          'registeredAt': DateTime.now().subtract(const Duration(days: 2)),
          'documents': ['license.pdf', 'certificate.pdf'],
        },
        {
          'id': '5',
          'name': 'Dr. Jennifer Liu',
          'email': 'jennifer.liu@dopply.com',
          'specialization': 'Obstetrics',
          'licenseNumber': 'MD-2024-002',
          'registeredAt': DateTime.now().subtract(const Duration(hours: 12)),
          'documents': ['license.pdf', 'certificate.pdf', 'recommendation.pdf'],
        },
      ];

      state = state.copyWith(
        users: mockUsers,
        pendingDoctors: mockPendingDoctors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> validateDoctor(String doctorId, bool approve) async {
    try {
      // Mock validation API call
      await Future.delayed(const Duration(milliseconds: 500));

      if (approve) {
        // Update user's validation status
        final updatedUsers =
            state.users.map((user) {
              if (user['id'] == doctorId) {
                return {...user, 'isValid': true};
              }
              return user;
            }).toList();

        // Remove from pending doctors
        final updatedPendingDoctors =
            state.pendingDoctors
                .where((doctor) => doctor['id'] != doctorId)
                .toList();

        state = state.copyWith(
          users: updatedUsers,
          pendingDoctors: updatedPendingDoctors,
        );
      } else {
        // Remove from both lists (rejected)
        final updatedUsers =
            state.users.where((user) => user['id'] != doctorId).toList();
        final updatedPendingDoctors =
            state.pendingDoctors
                .where((doctor) => doctor['id'] != doctorId)
                .toList();

        state = state.copyWith(
          users: updatedUsers,
          pendingDoctors: updatedPendingDoctors,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Mock delete API call
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedUsers =
          state.users.where((user) => user['id'] != userId).toList();

      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// System Analytics State
class SystemAnalyticsState {
  final Map<String, dynamic> dailyStats;
  final Map<String, dynamic> weeklyStats;
  final Map<String, dynamic> monthlyStats;
  final List<Map<String, dynamic>> recentActivities;
  final bool isLoading;
  final String? error;

  const SystemAnalyticsState({
    this.dailyStats = const {},
    this.weeklyStats = const {},
    this.monthlyStats = const {},
    this.recentActivities = const [],
    this.isLoading = false,
    this.error,
  });

  SystemAnalyticsState copyWith({
    Map<String, dynamic>? dailyStats,
    Map<String, dynamic>? weeklyStats,
    Map<String, dynamic>? monthlyStats,
    List<Map<String, dynamic>>? recentActivities,
    bool? isLoading,
    String? error,
  }) {
    return SystemAnalyticsState(
      dailyStats: dailyStats ?? this.dailyStats,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      recentActivities: recentActivities ?? this.recentActivities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// System Analytics Notifier
class SystemAnalyticsNotifier extends StateNotifier<SystemAnalyticsState> {
  SystemAnalyticsNotifier() : super(const SystemAnalyticsState());

  final MonitoringApiService _monitoringApiService = MonitoringApiService();
  final UserApiService _userApiService = UserApiService();

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Mock analytics data
      await Future.delayed(const Duration(milliseconds: 600));

      final mockRecentActivities = [
        {
          'id': '1',
          'type': 'user_registration',
          'description': 'New patient registered: Emily Davis',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
          'severity': 'info',
        },
        {
          'id': '2',
          'type': 'monitoring_session',
          'description':
              'Heart rate monitoring session completed for Patient #123',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
          'severity': 'success',
        },
        {
          'id': '3',
          'type': 'system_alert',
          'description': 'High heart rate detected during monitoring session',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'severity': 'warning',
        },
        {
          'id': '4',
          'type': 'doctor_validation',
          'description': 'Dr. Michael Chen submitted validation documents',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
          'severity': 'info',
        },
      ];

      state = state.copyWith(
        dailyStats: {
          'sessions': 47,
          'new_users': 12,
          'alerts': 3,
          'validations': 2,
        },
        weeklyStats: {
          'sessions': 324,
          'new_users': 89,
          'alerts': 18,
          'validations': 15,
        },
        monthlyStats: {
          'sessions': 1456,
          'new_users': 387,
          'alerts': 76,
          'validations': 68,
        },
        recentActivities: mockRecentActivities,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Providers
final systemStatsProvider =
    StateNotifierProvider<SystemStatsNotifier, SystemStats>((ref) {
      return SystemStatsNotifier();
    });

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
      return UserManagementNotifier();
    });

final systemAnalyticsProvider =
    StateNotifierProvider<SystemAnalyticsNotifier, SystemAnalyticsState>((ref) {
      return SystemAnalyticsNotifier();
    });
