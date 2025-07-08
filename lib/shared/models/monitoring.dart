// Monitoring Models - Domain Entities
// Sesuai dengan response API monitoring endpoints

/// BMP Data Point untuk chart dan monitoring
class BmpDataPoint {
  final double time;
  final double bpm;

  const BmpDataPoint({required this.time, required this.bpm});

  factory BmpDataPoint.fromJson(Map<String, dynamic> json) {
    return BmpDataPoint(
      time: (json['time'] as num).toDouble(),
      bpm: (json['bpm'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time, 'bpm': bpm};
  }
}

/// Monitoring Record dari API response
class MonitoringRecord {
  final int id;
  final DateTime createdAt;
  final String monitoringResult;
  final String classification;
  final List<BmpDataPoint> bmpData;
  final int? patientId;
  final int? doctorId;
  final String? doctorNote;

  const MonitoringRecord({
    required this.id,
    required this.createdAt,
    required this.monitoringResult,
    required this.classification,
    required this.bmpData,
    this.patientId,
    this.doctorId,
    this.doctorNote,
  });

  factory MonitoringRecord.fromJson(Map<String, dynamic> json) {
    return MonitoringRecord(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      monitoringResult: json['monitoring_result'] as String,
      classification: json['classification'] as String,
      bmpData:
          (json['bpm_data'] as List)
              .map((e) => BmpDataPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
      patientId: json['patient_id'] as int?,
      doctorId: json['doctor_id'] as int?,
      doctorNote: json['doctor_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'monitoring_result': monitoringResult,
      'classification': classification,
      'bmp_data': bmpData.map((e) => e.toJson()).toList(),
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (doctorNote != null) 'doctor_note': doctorNote,
    };
  }

  /// Get average BPM
  double get averageBpm {
    if (bmpData.isEmpty) return 0.0;
    return bmpData.map((e) => e.bpm).reduce((a, b) => a + b) / bmpData.length;
  }

  /// Check if classification is normal
  bool get isNormal => classification.toLowerCase() == 'normal';

  /// Check if classification indicates warning
  bool get isWarning =>
      classification.toLowerCase().contains('warning') ||
      classification.toLowerCase().contains('abnormal');

  /// Check if classification indicates critical
  bool get isCritical =>
      classification.toLowerCase().contains('critical') ||
      classification.toLowerCase().contains('emergency');
}

/// Monitoring Session untuk real-time monitoring
class MonitoringSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<double> bmpValues;
  final String status; // 'ongoing', 'completed', 'cancelled'
  final int? patientId;
  final int? doctorId;

  const MonitoringSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.bmpValues,
    required this.status,
    this.patientId,
    this.doctorId,
  });

  /// Duration of monitoring session
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if session is ongoing
  bool get isOngoing => status == 'ongoing';

  /// Check if session is completed
  bool get isCompleted => status == 'completed';

  /// Get average BPM for session
  double get averageBpm {
    if (bmpValues.isEmpty) return 0.0;
    return bmpValues.reduce((a, b) => a + b) / bmpValues.length;
  }

  /// Get max BPM
  double get maxBpm =>
      bmpValues.isEmpty ? 0.0 : bmpValues.reduce((a, b) => a > b ? a : b);

  /// Get min BPM
  double get minBpm =>
      bmpValues.isEmpty ? 0.0 : bmpValues.reduce((a, b) => a < b ? a : b);
}
