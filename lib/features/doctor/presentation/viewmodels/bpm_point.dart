/// Model titik data BPM (Beat Per Minute) pada waktu tertentu.
/// Digunakan untuk visualisasi dan analisis data monitoring detak jantung janin.
class BpmPoint {
  /// Waktu relatif sejak monitoring dimulai.
  final Duration time;

  /// Nilai BPM pada waktu tersebut.
  final int bpm;

  /// Membuat instance BpmPoint.
  /// [time] adalah waktu relatif, [bpm] adalah nilai detak jantung.
  BpmPoint(this.time, this.bpm);
}
