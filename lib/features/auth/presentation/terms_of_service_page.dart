import 'package:flutter/material.dart';

/// **Terms of Service Page**
///
/// Displays the terms of service for the Dopply medical monitoring application.
/// Contains information about service usage, responsibilities, and legal agreements.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat Layanan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            // Header
            Text(
              'Syarat Layanan Dopply',
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
              icon: Icons.handshake_outlined,
              title: '1. Penerimaan Syarat',
            ),
            SizedBox(height: 8),
            Text(
              'Dengan menggunakan aplikasi Dopply, Anda menyatakan bahwa:\n'
              '• Anda telah membaca dan memahami syarat layanan ini\n'
              '• Anda setuju untuk terikat dengan semua ketentuan yang berlaku\n'
              '• Anda berusia minimal 18 tahun atau memiliki persetujuan wali\n'
              '• Anda menggunakan aplikasi untuk tujuan medis yang sah',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 2
            _SectionHeader(
              icon: Icons.medical_services_outlined,
              title: '2. Penggunaan Layanan',
            ),
            SizedBox(height: 8),
            Text(
              'Aplikasi Dopply harus digunakan dengan ketentuan:\n'
              '• Hanya untuk monitoring kesehatan personal\n'
              '• Mengikuti petunjuk dan rekomendasi dokter\n'
              '• Tidak menyalahgunakan data atau fitur aplikasi\n'
              '• Menjaga kerahasiaan akun dan password\n'
              '• Melaporkan masalah teknis atau keamanan yang ditemukan',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 3
            _SectionHeader(
              icon: Icons.warning_amber_outlined,
              title: '3. Penolakan Tanggung Jawab',
            ),
            SizedBox(height: 8),
            Text(
              'Penting untuk dipahami bahwa:\n'
              '• Aplikasi ini TIDAK menggantikan konsultasi medis profesional\n'
              '• Keputusan medis harus selalu dikonsultasikan dengan dokter\n'
              '• Dopply tidak bertanggung jawab atas keputusan medis yang diambil berdasarkan data aplikasi\n'
              '• Akurasi data tergantung pada perangkat dan input pengguna\n'
              '• Dalam keadaan darurat, segera hubungi layanan kesehatan terdekat',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 4
            _SectionHeader(
              icon: Icons.privacy_tip_outlined,
              title: '4. Privasi dan Data',
            ),
            SizedBox(height: 8),
            Text(
              'Terkait dengan data pribadi Anda:\n'
              '• Data dikumpulkan sesuai Kebijakan Privasi yang berlaku\n'
              '• Anda bertanggung jawab atas keakuratan data yang dimasukkan\n'
              '• Data kesehatan akan dijaga kerahasiaannya\n'
              '• Anda dapat mengakses dan mengelola data pribadi melalui aplikasi\n'
              '• Penggunaan data mengikuti standar keamanan medis internasional',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 5
            _SectionHeader(
              icon: Icons.update_outlined,
              title: '5. Perubahan Syarat',
            ),
            SizedBox(height: 8),
            Text(
              'Syarat layanan dapat berubah sewaktu-waktu:\n'
              '• Perubahan akan diinformasikan melalui aplikasi\n'
              '• Notifikasi perubahan akan dikirim ke email terdaftar\n'
              '• Penggunaan aplikasi setelah perubahan menandakan persetujuan\n'
              '• Jika tidak setuju dengan perubahan, Anda dapat menghentikan penggunaan aplikasi',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 6
            _SectionHeader(
              icon: Icons.block_outlined,
              title: '6. Penghentian Layanan',
            ),
            SizedBox(height: 8),
            Text(
              'Akses ke aplikasi dapat dihentikan jika:\n'
              '• Terjadi pelanggaran syarat layanan\n'
              '• Penggunaan aplikasi untuk tujuan yang melanggar hukum\n'
              '• Aktivitas yang membahayakan pengguna lain\n'
              '• Permintaan penghentian dari pengguna sendiri\n'
              '• Penghentian layanan secara keseluruhan oleh Dopply',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 7
            _SectionHeader(
              icon: Icons.gavel_outlined,
              title: '7. Hukum yang Berlaku',
            ),
            SizedBox(height: 8),
            Text(
              'Syarat layanan ini:\n'
              '• Diatur oleh hukum yang berlaku di Republik Indonesia\n'
              '• Mengikuti regulasi kesehatan dan privasi data nasional\n'
              '• Sengketa diselesaikan melalui mediasi atau pengadilan yang berwenang\n'
              '• Berlaku untuk semua pengguna aplikasi Dopply',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Section 8
            _SectionHeader(
              icon: Icons.contact_support_outlined,
              title: '8. Kontak & Bantuan',
            ),
            SizedBox(height: 8),
            Text(
              'Untuk pertanyaan tentang syarat layanan:\n\n'
              '📧 Email: legal@dopply.my.id\n'
              '📞 Telepon: +62-XXX-XXXX-XXXX\n'
              '🏥 Alamat: Jl. Kesehatan No. 123, Jakarta\n'
              '⏰ Jam Operasional: Senin-Jumat 08:00-17:00 WIB\n\n'
              'Tim legal kami siap membantu Anda.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),

            // Footer
            Divider(),
            SizedBox(height: 16),
            Text(
              'Terakhir diperbarui: 2 Juli 2025\n'
              'Berlaku sejak: 1 Januari 2025\n'
              'Versi: 1.2',
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
