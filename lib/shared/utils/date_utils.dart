/// Utility untuk format tanggal Indonesia sederhana.
String formatTanggalIndo(dynamic startTime) {
  if (startTime == null) return '-';
  try {
    final dt = DateTime.parse(startTime.toString());
    final bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  } catch (_) {
    return startTime.toString();
  }
}
