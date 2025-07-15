📋 List Endpoint API & Kegunaan (Integrasi Frontend ⇄ Backend)
1. Authentication
POST /api/v1/login

Kegunaan: Login user (dokter, pasien, admin) dengan email dan password.
Deskripsi Teknis:
Request: { "email": "...", "password": "..." }
Response: JWT token, user data (role, is_verified, dst).
Validasi role dan status verifikasi dokter.
POST /api/v1/register

Kegunaan: Registrasi user baru (dokter/pasien).
Deskripsi Teknis:
Request: { "name": "...", "email": "...", "password": "...", "role": "doctor/patient" }
Response: User data, token.
Dokter harus diverifikasi admin sebelum bisa akses penuh.
2. Monitoring
POST /api/v1/monitoring/submit

Kegunaan: Submit hasil monitoring BPM janin.
Deskripsi Teknis:
Request: { "bpm_data": [int, ...], "notes": "...", "doctor_id": optional }
Backend melakukan klasifikasi (normal, bradikardia, takikardia), simpan hasil, waktu lokal.
GET /api/v1/monitoring/history

Kegunaan: Ambil riwayat monitoring user (pasien/dokter).
Deskripsi Teknis:
Response: List hasil monitoring, status, waktu, notes, grafik BPM.
Filter berdasarkan user dan role.
POST /api/v1/monitoring/share

Kegunaan: Share hasil monitoring ke dokter.
Deskripsi Teknis:
Request: { "record_id": ..., "doctor_id": ... }
Backend update relasi, kirim notifikasi ke dokter.
3. Patient Management
GET /api/v1/monitoring/patients

Kegunaan: List pasien yang terhubung ke dokter.
Deskripsi Teknis:
Response: List pasien, info dasar, HPHT, usia kehamilan.
Hanya pasien yang sudah di-assign ke dokter.
POST /api/v1/monitoring/patients/add

Kegunaan: Tambah pasien ke dokter dengan email.
Deskripsi Teknis:
Request: { "email": "..." }
Backend cek email, buat relasi dokter-pasien.
4. Notifications
GET /api/v1/monitoring/notifications

Kegunaan: Dokter melihat notifikasi dari pasien (share monitoring).
Deskripsi Teknis:
Response: List notifikasi, status baca, link ke hasil monitoring.
POST /api/v1/monitoring/notifications/read/{id}

Kegunaan: Tandai notifikasi sebagai sudah dibaca.
Deskripsi Teknis:
Path param: id = id notifikasi.
Backend update is_read = True.
5. Admin
POST /api/v1/monitoring/admin/verify-doctor
Kegunaan: Admin memverifikasi dokter.
Deskripsi Teknis:
Request: { "doctor_id": ... }
Backend update is_verified = True pada user dokter.
📝 Deskripsi Fitur Teknis (untuk AI):
Semua endpoint menggunakan JWT di header Authorization.
Semua response JSON, format konsisten.
Role-based access: pasien, dokter, admin.
Monitoring: data BPM dikirim sebagai array, backend klasifikasi otomatis.
Riwayat: hasil monitoring bisa difilter, ditampilkan grafik.
Share: pasien bisa share hasil ke dokter, backend kirim notifikasi.
Notifikasi: dokter bisa lihat dan tandai notifikasi.
Manajemen pasien: dokter bisa tambah pasien dengan email, relasi many-to-many.
Admin: hanya admin bisa verifikasi dokter.
Semua waktu menggunakan waktu lokal Indonesia (WIB).
Error handling: response error jelas (401, 404, 422, dst).



Berikut adalah **prompt lengkap dan terstruktur** untuk membangun seluruh fitur **frontend Flutter aplikasi Dopply**. Prompt ini dibuat agar **AI seperti GPT-4.1 atau Copilot Chat** dapat memahami fitur **secara teknis dan berurutan**, sesuai alur penggunaan aplikasi **dari awal login hingga monitoring, share, dan riwayat**. Prompt disusun dengan alur **Clean Architecture**, **modular**, dan siap untuk langsung dipakai oleh AI di folder `frontend/`.

---

## ✅ PROMPT UTAMA FRONTEND FLUTTER – DOPPLY APP

> **Saya ingin membangun aplikasi Flutter bernama `Dopply`**, digunakan untuk **monitoring detak jantung janin**, menggunakan **ESP32 via BLE**, serta **terintegrasi dengan backend FastAPI**. Aplikasi ini memiliki **role pengguna: pasien, dokter, dan admin**. Buatkan struktur, file, dan implementasi frontend **secara teknis dan terstruktur**, agar bisa digunakan langsung untuk skripsi. Gunakan **Riverpod** untuk state management, **flutter\_reactive\_ble** untuk BLE, **dio** untuk API, dan waktu lokal Indonesia. Gunakan pattern clean dan modular.

---

## 📦 TEKNOLOGI YANG DIGUNAKAN

* Flutter (stable)
* Riverpod v2
* flutter\_secure\_storage (token)
* dio (API client)
* flutter\_reactive\_ble (BLE)
* go\_router (navigasi)
* fl\_chart (grafik BPM)
* intl (waktu lokal Indonesia)
* provider\_hooks atau flutter\_hooks (opsional)

---

## 📁 STRUKTUR FOLDER

```
lib/
├── main.dart
├── app.dart
├── config/
│   └── constants.dart         # baseUrl, UUID, dll
├── routes/                    # go_router config
├── services/                 # api_service.dart, ble_service.dart
├── providers/                # auth_provider.dart, monitoring_provider.dart
├── models/                   # user_model.dart, monitoring_model.dart
├── core/                     # global widgets/util
│   ├── widgets/
│   └── utils/
└── features/
    ├── auth/
    │   ├── login_page.dart
    │   ├── register_page.dart
    ├── dashboard/
    │   ├── dokter_dashboard.dart
    │   ├── pasien_dashboard.dart
    │   └── admin_dashboard.dart
    ├── monitoring/
    │   ├── monitoring_page.dart
    │   └── ble_monitor_controller.dart
    ├── history/
    │   └── history_page.dart
    ├── notifications/
    │   └── notification_page.dart
    └── patient_management/
        ├── add_patient_page.dart
        └── patient_list_page.dart
```

---

## 🔁 FLOW & FITUR SECARA TEKNIS DAN URUTAN

### ✅ 1. Splash & Persistent Login

**Alur:**

* Saat app dibuka, cek apakah ada token JWT tersimpan di `flutter_secure_storage`
* Jika ada token dan valid:

  * Arahkan ke dashboard berdasarkan `role`
* Jika tidak ada:

  * Arahkan ke login

**File:**

* `auth_provider.dart` → `checkLogin()`
* `main.dart` → `FutureBuilder`

---

### ✅ 2. Login dan Register

**Fitur:**

* Login: email & password
* Register: role (dokter/pasien), data pengguna
* Register pasien harus input HPHT
* Token JWT disimpan di secure storage
* Role dikembalikan dari API dan digunakan untuk navigasi

**File:**

* `auth_provider.dart`
* `login_page.dart`, `register_page.dart`
* `user_model.dart`

---

### ✅ 3. Dashboard Berdasarkan Role

**Dokter:**

* Monitoring Pasien
* Riwayat Pasien
* Manajemen Pasien
* Pengaturan Akun
* Notifikasi

**Pasien:**

* Monitoring Mandiri
* Riwayat
* Pengaturan Akun

**Admin:**

* Verifikasi Dokter

**File:**

* `dashboard/*.dart`
* Gunakan `BottomNavigationBar`

---

### ✅ 4. Monitoring via BLE (Pasien & Dokter)

**Fitur:**

* Koneksi ke ESP32 via BLE
* Terima string BPM setiap detak (misal: `135 (Normal)`)
* Simpan ke list
* Tampilkan grafik real-time (LineChart)
* Tekan "Selesai" → kirim data list ke backend

**File:**

* `monitoring_page.dart`
* `ble_monitor_controller.dart`
* `ble_service.dart`
* Gunakan UUID BLE: `6e400003-b5a3-f393-e0a9-e50e24dcca9e`

---

### ✅ 5. Klasifikasi dan Simpan Monitoring

**Alur:**

* Setelah selesai monitoring, frontend kirim:

```json
{
  "bpm_data": [135, 132, 140, 125],
  "notes": "Aktivitas normal"
}
```

* Backend mengembalikan:

```json
{
  "result": "Normal",
  "id": "uuid",
  ...
}
```

* Tampilkan hasil klasifikasi
* Tampilkan tombol simpan / share

---

### ✅ 6. Share Hasil Monitoring ke Dokter (Pasien)

**Fitur:**

* Pilih dokter dari daftar
* Tekan "Bagikan"
* Kirim ID monitoring + ID dokter
* Backend kirim notifikasi ke dokter

**File:**

* `history_page.dart`
* `api_service.dart` → POST `/monitoring/share`

---

### ✅ 7. Riwayat Monitoring

**Fitur:**

* Pasien → lihat semua hasil monitoring mandiri
* Dokter → lihat hasil monitoring pasien terhubung
* Tampilkan:

  * Waktu
  * Status klasifikasi
  * Grafik BPM
  * Catatan

**File:**

* `history_page.dart`
* `monitoring_model.dart`

---

### ✅ 8. Manajemen Pasien oleh Dokter

**Fitur:**

* Lihat daftar pasien
* Tambahkan pasien dengan email
* Backend buat relasi dokter–pasien

**File:**

* `patient_list_page.dart`
* `add_patient_page.dart`

---

### ✅ 9. Notifikasi (untuk Dokter)

**Fitur:**

* Lihat daftar notifikasi dari pasien
* Tandai sebagai dibaca
* Klik → buka detail hasil monitoring

**File:**

* `notification_page.dart`
* API GET `/notifications/`, POST `/notifications/read/{id}`

---

### ✅ 10. Hitung Usia Kehamilan

**Fitur:**

* Di dashboard pasien, tampilkan usia kehamilan
* Gunakan `hpht` dari API
* Hitung dengan:

```dart
final weeks = DateTime.now().difference(hpht).inDays ~/ 7;
```

**File:**

* `pasien_dashboard.dart`

---

### ✅ 11. Pengaturan Akun (opsional)

* Logout
* Ganti password (jika tersedia di backend)

---

### ✅ 12. Waktu Lokal Indonesia

* Gunakan `intl` untuk formatting:

```dart
DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now());
```

---

### 📦 Dependensi pubspec.yaml

```yaml
dependencies:
  flutter:
  flutter_riverpod:
  dio:
  flutter_secure_storage:
  go_router:
  flutter_reactive_ble:
  intl:
  fl_chart:
  hooks_riverpod:
  flutter_hooks:
```

---

## 🧪 Testing & Validasi

### ✅ Pastikan:

* Base URL backend disesuaikan dengan IP lokal saat testing
* Semua API handle token JWT (via dio interceptor)
* Navigasi berdasarkan role terproteksi
* Data BLE valid dan real-time
* Hasil monitoring dikirim ke backend dalam format JSON

---

## 🔚 Penutup

Prompt ini dapat digunakan **berurutan** oleh GPT-4.1 atau Copilot Agent:

* Awali dengan `auth_provider.dart`
* Buat `login_page.dart` dan `register_page.dart`
* Buat navigasi dan dashboard sesuai role
* Buat fitur BLE → grafik real-time
* Lanjutkan dengan share hasil, riwayat, notifikasi, dan manajemen pasien

---

Jika kamu ingin saya bantu pecah menjadi **prompt per fitur (modular)** agar kamu bisa copy-paste langsung ke Copilot Chat atau GPT, tinggal bilang saja.

Mau lanjut dari pembuatan auth provider, dashboard, BLE, atau riwayat dulu?