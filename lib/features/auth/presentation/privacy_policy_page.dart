import 'package:flutter/material.dart';

/// **Privacy Policy Page**
///
/// Displays the privacy policy for the Dopply medical monitoring application.
/// Contains information about data collection, usage, security, and user rights.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            // Header
            Text(
              'Kebijakan Privasi Dopply',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aplikasi Monitoring Kesehatan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),

            // Section 1
            _SectionHeader(
              icon: Icons.info_outline,
              title: '1. Informasi yang Dikumpulkan',
            ),
            SizedBox(height: 8),
            Text(
              'Kami mengumpulkan data kesehatan yang Anda masukkan dalam aplikasi untuk keperluan monitoring kondisi medis Anda. Data yang dikumpulkan meliputi:\n'
              '• Data biometrik (detak jantung, tekanan darah)\n'
              '• Informasi profil pengguna\n'
              '• Data riwayat monitoring\n'
              '• Log aktivitas aplikasi',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 2
            _SectionHeader(
              icon: Icons.security,
              title: '2. Penggunaan Informasi',
            ),
            SizedBox(height: 8),
            Text(
              'Data Anda digunakan secara eksklusif untuk:\n'
              '• Menyediakan layanan monitoring kesehatan\n'
              '• Membantu dokter dalam memberikan diagnosa\n'
              '• Meningkatkan kualitas layanan aplikasi\n'
              '• Memberikan notifikasi dan peringatan kesehatan\n\n'
              'Data TIDAK akan dibagikan kepada pihak ketiga tanpa persetujuan eksplisit Anda.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 3
            _SectionHeader(icon: Icons.lock_outline, title: '3. Keamanan Data'),
            SizedBox(height: 8),
            Text(
              'Kami menerapkan langkah-langkah keamanan yang ketat:\n'
              '• Enkripsi data end-to-end\n'
              '• Autentikasi berlapis\n'
              '• Server dengan sertifikat keamanan standar medis\n'
              '• Audit keamanan berkala\n'
              '• Backup data terjadwal dan aman',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 4
            _SectionHeader(
              icon: Icons.person_outline,
              title: '4. Hak Pengguna',
            ),
            SizedBox(height: 8),
            Text(
              'Sebagai pengguna, Anda memiliki hak untuk:\n'
              '• Mengakses semua data pribadi Anda\n'
              '• Memperbaiki atau mengupdate informasi\n'
              '• Menghapus akun dan data pribadi\n'
              '• Mengekspor data dalam format yang dapat dibaca\n'
              '• Menarik persetujuan penggunaan data',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 5
            _SectionHeader(icon: Icons.update, title: '5. Perubahan Kebijakan'),
            SizedBox(height: 8),
            Text(
              'Kebijakan privasi dapat berubah seiring dengan perkembangan aplikasi. Perubahan akan diinformasikan melalui:\n'
              '• Notifikasi dalam aplikasi\n'
              '• Email ke alamat terdaftar\n'
              '• Pengumuman di halaman utama\n\n'
              'Penggunaan aplikasi setelah perubahan menandakan persetujuan Anda terhadap kebijakan yang baru.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 6
            _SectionHeader(
              icon: Icons.contact_support,
              title: '6. Kontak & Bantuan',
            ),
            SizedBox(height: 8),
            Text(
              'Jika Anda memiliki pertanyaan atau keluhan terkait privasi, silakan hubungi:\n\n'
              '📧 Email: privacy@dopply.my.id\n'
              '📞 Telepon: +62-XXX-XXXX-XXXX\n'
              '🏥 Alamat: Jl. Kesehatan No. 123, Jakarta\n\n'
              'Tim privacy kami akan merespon dalam 1x24 jam.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Footer
            Divider(),
            SizedBox(height: 16),
            Text(
              'Terakhir diperbarui: 2 Juli 2025\n'
              'Berlaku sejak: 1 Januari 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
