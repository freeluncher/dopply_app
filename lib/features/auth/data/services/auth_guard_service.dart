import 'package:go_router/go_router.dart';

// Import shared User entity
import 'package:dopply_app/shared/models/user.dart';

/// Enhanced Auth Guard Service for route protection
///
/// Uses shared User model for consistent authentication
/// Provides comprehensive role-based access control
class AuthGuardService {
  /// Check if user can access the requested route
  /// Returns redirect path if access denied, null if allowed
  static String? canAccess(GoRouterState state, dynamic user) {
    // Handle User entity
    final isLoggedIn = user != null;
    String? userRole;

    if (user is User) {
      userRole = user.role;
    }

    final isAdmin = userRole == 'admin';
    final isDoctor = userRole == 'doctor';
    final isPatient = userRole == 'patient';

    print('[AUTH_GUARD] Checking access for: ${state.location}');
    print('[AUTH_GUARD] User logged in: $isLoggedIn, Role: $userRole');

    // Public routes that don't require authentication
    final publicRoutes = ['/', '/login', '/register'];

    if (publicRoutes.contains(state.location)) {
      return null; // Allow access
    }

    // Require authentication for all other routes
    if (!isLoggedIn) {
      print('[AUTH_GUARD] Redirecting to login - user not authenticated');
      return '/login';
    }

    // Role-based access control

    // Admin routes - only admin can access
    if (state.location.startsWith('/admin')) {
      if (!isAdmin) {
        print(
          '[AUTH_GUARD] Access denied - admin required for: ${state.location}',
        );
        return _getDashboardForRole(userRole);
      }
      return null; // Admin can access
    }

    // Doctor routes - only doctors can access
    if (state.location.startsWith('/doctor')) {
      if (!isDoctor) {
        print(
          '[AUTH_GUARD] Access denied - doctor required for: ${state.location}',
        );
        return _getDashboardForRole(userRole);
      }
      return null; // Doctor can access
    }

    // Patient routes - only patients can access
    if (state.location.startsWith('/patient')) {
      if (!isPatient) {
        print(
          '[AUTH_GUARD] Access denied - patient required for: ${state.location}',
        );
        return _getDashboardForRole(userRole);
      }
      return null; // Patient can access
    }

    // Dashboard routes - redirect to appropriate dashboard
    if (state.location.contains('Dashboard')) {
      final expectedRoute = _getDashboardForRole(userRole);
      if (state.location != expectedRoute) {
        print('[AUTH_GUARD] Redirecting to correct dashboard: $expectedRoute');
        return expectedRoute;
      }
      return null;
    }

    // General authenticated routes - allow if logged in
    print('[AUTH_GUARD] Access granted for authenticated user');
    return null;
  }

  /// Get the appropriate dashboard route for user role
  static String _getDashboardForRole(String? role) {
    switch (role) {
      case 'admin':
        return '/adminDashboard';
      case 'doctor':
        return '/doctorDashboard';
      case 'patient':
        return '/patientDashboard';
      default:
        return '/login';
    }
  }

  /// Check if user has specific role
  static bool hasRole(dynamic user, String requiredRole) {
    if (user is User) {
      return user.role == requiredRole;
    }
    return false;
  }

  /// Check if user has any of the specified roles
  static bool hasAnyRole(dynamic user, List<String> requiredRoles) {
    String? userRole;

    if (user is User) {
      userRole = user.role;
    }

    return userRole != null && requiredRoles.contains(userRole);
  }

  /// Check if route requires authentication
  static bool requiresAuth(String path) {
    final publicRoutes = ['/', '/login', '/register'];
    return !publicRoutes.contains(path);
  }

  /// Get user role as string
  static String? getUserRole(dynamic user) {
    if (user is User) {
      return user.role;
    }
    return null;
  }
}
