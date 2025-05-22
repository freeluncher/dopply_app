# Dopply App

Aplikasi Monitoring Fetal BPM Berbasis Flutter

---

## Deskripsi
Dopply App adalah aplikasi mobile berbasis Flutter yang digunakan untuk monitoring detak jantung janin (fetal BPM) menggunakan perangkat ESP32 BLE. Aplikasi ini mendukung tiga peran utama: **Pasien**, **Dokter**, dan **Admin**. Setiap peran memiliki fitur dan akses yang berbeda sesuai kebutuhan monitoring dan manajemen data.

---

## Fitur Utama

### 1. Pasien
- Koneksi BLE ke ESP32 untuk monitoring BPM secara real-time
- Melihat riwayat monitoring
- Mengubah email dan password

### 2. Dokter
- Monitoring BPM pasien secara real-time
- Melihat dan mengelola riwayat monitoring pasien
- Menambahkan/memilih pasien
- Mengubah email dan password

### 3. Admin
- Manajemen user (CRUD: tambah, edit, hapus user)
- Melihat daftar user
- Mengubah email dan password

---

## Struktur Folder Penting

- `lib/features/patient/` : Fitur dan halaman untuk pasien
- `lib/features/doctor/`  : Fitur dan halaman untuk dokter
- `lib/features/admin/`   : Fitur dan halaman untuk admin
- `lib/core/`             : Service, utilitas, dan widget global
- `lib/app/`              : Router dan tema aplikasi
- `android/` & `ios/`     : Konfigurasi native Android/iOS

---

## Cara Build APK (Android)
1. Pastikan semua dependensi sudah terinstall:
   ```powershell
   flutter pub get
   ```
2. Build APK release:
   ```powershell
   flutter build apk --release
   ```
3. File APK akan tersedia di:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

---

## Koneksi ke ESP32 (BLE)
- Pastikan perangkat ESP32 sudah menyala dan menyiarkan BLE dengan nama yang sesuai.
- Tekan tombol **Connect ESP32** pada halaman monitoring.
- Jika koneksi berhasil, data BPM akan tampil secara real-time.

---

## Konfigurasi Backend
- Pastikan endpoint API sudah sesuai dengan kebutuhan frontend (lihat prompt backend pada dokumentasi pengembangan).
- Endpoint penting: `/users`, `/account/email`, `/account/password`, dsb.

---

## Catatan Pengembangan
- Untuk pengembangan lebih lanjut, perhatikan file `proguard-rules.pro` dan dependensi pada `build.gradle.kts` jika ingin build APK release.
- Jika ada error R8 saat build, tambahkan aturan dari `missing_rules.txt` ke `proguard-rules.pro`.

---

## Kontributor
- Developer: [freeluncher]
- Untuk pertanyaan atau bantuan, silakan hubungi via email/WA sesuai kesepakatan.

---

## Lisensi
Aplikasi ini dikembangkan untuk keperluan tugas akhir/skripsi dan penggunaan edukasi.
