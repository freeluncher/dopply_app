# 📱 Frontend Flutter - Simplified FIX.md

## 🎯 Overview
Dokumentasi ini berisi **spesifikasi frontend Flutter yang disederhanakan** untuk aplikasi Dopply, disesuaikan dengan endpoint backend yang sudah ada dan fokus pada fitur-fitur essential saja.

---

## 🎯 Prinsip Simplifikasi
- ✅ **Minimal Viable Product (MVP)** approach
- ✅ **Role-based UI yang clean** dan tidak overwhelming
- ✅ **Fitur core saja** - hapus fitur yang tidak essential
- ✅ **Endpoint sesuai backend** yang sudah diimplementasi
- ✅ **User experience yang smooth** dan tidak kompleks
- ✅ **Pertahankan design system yang sudah ada** - Jangan ubah color scheme, typography, atau component style yang sudah diimplementasi
- ✅ **Remove excessive features** - Hapus hanya fitur/tampilan yang berlebihan dan tidak ada di FIX.md

---

## 📁 Struktur Folder Frontend (Simplified)

```
frontend/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── api_client.dart          # Dio HTTP client
│   │   ├── storage.dart             # Secure storage
│   │   └── routes.dart              # Go router
│   ├── models/
│   │   ├── user.dart
│   │   ├── patient.dart
│   │   ├── monitoring.dart
│   │   └── notification.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── dashboard/
│   │   │   ├── patient_dashboard.dart
│   │   │   ├── doctor_dashboard.dart
│   │   │   └── admin_dashboard.dart
│   │   ├── monitoring/
│   │   │   ├── monitoring_screen.dart   # BLE + real-time chart
│   │   │   └── monitoring_result.dart   # Show result + share
│   │   ├── history/
│   │   │   └── history_screen.dart      # List monitoring history
│   │   └── shared/
│   │       ├── loading_screen.dart
│   │       └── error_screen.dart
│   ├── widgets/
│   │   ├── charts/
│   │   │   └── bpm_chart.dart          # Real-time BPM chart
│   │   └── common/
│   │       ├── app_bar.dart
│   │       ├── button.dart
│   │       └── input_field.dart
│   └── services/
│       ├── auth_service.dart           # Login, register, token
│       ├── monitoring_service.dart     # Submit, history, share
│       ├── patient_service.dart        # Patient management
│       ├── notification_service.dart   # Notifications
│       └── ble_service.dart           # ESP32 BLE connection
```

---

## 🎯 Simplified Features per Role

### 👤 **Patient Role** (3 fitur utama)
1. **Monitoring Mandiri**
   - Connect ke ESP32 via BLE
   - Real-time BPM chart
   - Submit hasil ke backend
   
2. **Lihat Riwayat**
   - List monitoring history sendiri
   - Detail hasil per monitoring
   
3. **Share ke Dokter** (Optional)
   - Share specific monitoring result
   - Send notification ke dokter

### 👨‍⚕️ **Doctor Role** (4 fitur utama)
1. **Monitoring Pasien**
   - Same monitoring interface seperti patient
   - Bisa add notes
   
2. **List Pasien**
   - Lihat daftar pasien yang di-assign
   - Basic patient info + HPHT
   
3. **Add Pasien** 
   - Add patient by email
   - Simple form input
   
4. **Notifikasi** (Simple)
   - List notifications dari pasien
   - Mark as read

### 👨‍💼 **Admin Role** (1 fitur utama)
1. **Verify Dokter**
   - List pending doctor verifications
   - Approve/verify doctors

### 🚫 **Fitur yang Dihapus/Disederhanakan**
- ❌ Hapus **Profile editing yang kompleks** - Keep basic profile view only
- ❌ Hapus **Advanced filtering/searching** - Keep simple list view
- ❌ Hapus **Complex charts/analytics** - Keep simple BPM chart only  
- ❌ Hapus **Multi-language support** - Keep Indonesian only
- ❌ Hapus **Theme switching** - Keep existing theme
- ❌ Hapus **Advanced notification settings** - Keep simple notifications
- ❌ Hapus **Export/Import data** - Keep basic view only
- ❌ Hapus **Advanced user management** - Keep basic role functionality

---

## 🔗 API Integration - Simplified Mapping

### Base Configuration
```dart
class ApiConfig {
  static const String baseUrl = 'https://dopply.my.id/api/v1';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer {token}' // From secure storage
  };
}
```

### Frontend ↔ Backend Endpoint Mapping

| Frontend Action | HTTP Method | Backend Endpoint | Purpose |
|----------------|-------------|------------------|---------|
| **Authentication** |
| Login | `POST` | `/login` | User login |
| Register | `POST` | `/register` | User registration |
| **Monitoring** |
| Submit monitoring | `POST` | `/monitoring/submit` | Save monitoring data |
| Get history | `GET` | `/monitoring/history` | Get user's monitoring history |
| Share to doctor | `POST` | `/monitoring/share` | Share monitoring with doctor |
| **Patient Management** |
| Get patients (doctor) | `GET` | `/monitoring/patients` | Doctor's patient list |
| Add patient (doctor) | `POST` | `/monitoring/patients/add` | Add patient to doctor |
| **Notifications** |
| Get notifications | `GET` | `/monitoring/notifications` | Get doctor notifications |
| Mark as read | `POST` | `/monitoring/notifications/read/{id}` | Mark notification read |
| **Admin** |
| Verify doctor | `POST` | `/monitoring/admin/verify-doctor` | Admin verify doctor |

---

## 📱 Screen Flow - Simplified

### 🔐 Authentication Flow
```
Splash Screen → Check Token
├─ Valid Token → Dashboard (by role)
└─ Invalid Token → Login Screen
                   └─ Register Screen (if needed)
```

### 👤 Patient Flow
```
Patient Dashboard
├─ Start Monitoring → BLE Connection → Real-time Chart → Result → (Optional Share)
├─ View History → History List → History Detail
└─ Profile → Basic info + logout
```

### 👨‍⚕️ Doctor Flow  
```
Doctor Dashboard
├─ Start Monitoring → Same as patient
├─ My Patients → Patient List → Patient Detail
├─ Add Patient → Simple Form
├─ Notifications → Notification List → Mark Read
└─ Profile → Basic info + logout
```

### 👨‍💼 Admin Flow
```
Admin Dashboard
├─ Verify Doctors → Pending List → Verify Action
└─ Profile → Basic info + logout
```

---

## 🔌 BLE Integration - Simplified

### ESP32 BLE Configuration
```dart
class BLEConfig {
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUUID = "87654321-4321-4321-4321-cba987654321";
}
```

### BLE Service (Simplified)
```dart
class BLEService {
  // 1. Scan for ESP32
  Future<void> scanAndConnect();
  
  // 2. Start monitoring (get real-time BPM)
  Stream<int> startMonitoring();
  
  // 3. Stop monitoring
  Future<List<int>> stopMonitoring();
  
  // 4. Disconnect
  Future<void> disconnect();
}
```

---

## 📊 Data Models - Simplified

### User Model
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'patient', 'doctor', 'admin'
  final bool? isVerified; // For doctors only
}
```

### Monitoring Model
```dart
class MonitoringResult {
  final int id;
  final List<int> bpmData;
  final String classification; // 'normal', 'bradikardia', 'takikardia'
  final DateTime createdAt;
  final String? notes;
  final int? gestationalAge;
}
```

### Patient Model
```dart
class Patient {
  final int id;
  final String name;
  final String email;
  final DateTime? hpht;
  final int? gestationalAge; // Calculated from HPHT
}
```

### Notification Model
```dart
class NotificationItem {
  final int id;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int recordId;
}
```

---

## 🎨 UI/UX Guidelines - Simplified

### Design Principles
- ✅ **Clean & Minimal** - No overwhelming UI
- ✅ **Pertahankan color scheme yang sudah ada** - Tidak mengubah tema warna yang sudah diimplementasi
- ✅ **Large touch targets** - Easy to use
- ✅ **Clear navigation** - Simple bottom nav atau drawer sesuai yang sudah ada
- ✅ **Loading states** - Always show loading/error states

### UI Component Guidelines
- ✅ **Pertahankan komponen UI yang sudah ada** untuk fitur-fitur di FIX.md
- ✅ **Hapus hanya tampilan yang berlebihan** dan tidak terpakai
- ✅ **Keep existing design system** - AppBar, Button, Card, Input styles
- ✅ **Maintain current navigation pattern** - Bottom nav, Drawer, atau Tab sesuai implementasi
- ✅ **Remove complex features** - Hilangkan UI untuk fitur yang tidak ada di FIX.md

---

## 🔧 State Management - Simplified with Riverpod

### Auth Provider
```dart
@riverpod
class AuthNotifier extends Notifier<User?> {
  User? build() => null;
  
  Future<void> login(String email, String password);
  Future<void> register(UserData userData);
  Future<void> logout();
}
```

### Monitoring Provider
```dart
@riverpod
class MonitoringNotifier extends Notifier<List<MonitoringResult>> {
  List<MonitoringResult> build() => [];
  
  Future<void> submitMonitoring(List<int> bpmData, String notes);
  Future<void> loadHistory();
  Future<void> shareWithDoctor(int recordId, int doctorId);
}
```

---

## 📱 Navigation - Simplified

### Route Configuration
```dart
final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),
    
    // Role-based dashboards
    GoRoute(path: '/patient', builder: (_, __) => PatientDashboard()),
    GoRoute(path: '/doctor', builder: (_, __) => DoctorDashboard()),
    GoRoute(path: '/admin', builder: (_, __) => AdminDashboard()),
    
    // Monitoring
    GoRoute(path: '/monitoring', builder: (_, __) => MonitoringScreen()),
    GoRoute(path: '/history', builder: (_, __) => HistoryScreen()),
  ],
);
```

---

## 🚀 Implementation Priority

### Phase 1 - Core MVP (Week 1)
1. ✅ Authentication (login/register)
2. ✅ Role-based dashboard navigation
3. ✅ Basic BLE connection to ESP32
4. ✅ Simple monitoring with real-time chart

### Phase 2 - Essential Features (Week 2)  
1. ✅ Submit monitoring data to backend
2. ✅ View monitoring history
3. ✅ Patient management for doctors
4. ✅ Basic notifications

### Phase 3 - Polish (Week 3)
1. ✅ Share monitoring feature
2. ✅ Admin doctor verification
3. ✅ UI/UX improvements (tanpa mengubah theme/color yang sudah ada)
4. ✅ Error handling & loading states
5. ✅ Remove excessive UI components yang tidak digunakan

---

## 📋 Technical Requirements

### Dependencies (Simplified)
```yaml
dependencies:
  flutter: sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # HTTP & Storage
  dio: ^5.3.2
  flutter_secure_storage: ^9.0.0
  
  # BLE
  flutter_reactive_ble: ^5.0.3
  
  # Navigation
  go_router: ^12.1.1
  
  # Charts
  fl_chart: ^0.65.0
  
  # UI
  flutter_material_design_icons: ^1.1.131
  
dev_dependencies:
  flutter_test: sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
```

### Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## ✅ Definition of Done

### ✅ Authentication Ready
- [ ] Login/register works with backend
- [ ] Token stored securely
- [ ] Role-based navigation
- [ ] Auto-logout on token expiry

### ✅ Monitoring Ready  
- [ ] ESP32 BLE connection stable
- [ ] Real-time BPM chart smooth
- [ ] Submit to backend successful
- [ ] Classification displayed correctly

### ✅ Role Features Ready
- [ ] Patient: monitoring + history
- [ ] Doctor: monitoring + patients + notifications  
- [ ] Admin: doctor verification

### ✅ Production Ready
- [ ] Error handling comprehensive
- [ ] Loading states everywhere
- [ ] Offline capability (basic)
- [ ] Performance optimized

---

## 🎯 Success Metrics

1. **User can complete monitoring** in < 3 minutes
2. **BLE connection success rate** > 95%
3. **API response time** < 2 seconds
4. **Crash rate** < 1%
5. **User rating** > 4.0/5.0

---

**Status**: 📋 **SPECIFICATION READY**  
**Target**: 🎯 **Minimal but Complete MVP**  
**Timeline**: 🗓️ **3 weeks development**  
**Date**: July 15, 2025
