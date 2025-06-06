import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/auth/domain/entities/user.dart';

class AuthGuardService {
  static String? canAccess(GoRouterState state, User? user) {
    final isLoggedIn = user != null;
    final isAdmin = user?.role == 'admin';

    // Jika belum login dan bukan di halaman login atau register
    if (!isLoggedIn &&
        state.location != '/login' &&
        state.location != '/register') {
      return '/login';
    }
    // Hanya admin boleh akses /admin dan turunannya
    if (state.location.startsWith('/admin') && !isAdmin) {
      return '/login';
    }
    // Tambahkan aturan role lain di sini jika perlu
    return null;
  }
}
