/// Model untuk medical record dari API
class MedicalRecord {
  final int id;
  final int patientId;
  final int? doctorId;
  final String source;
  final List<BpmDataPoint> bpmData;
  final String startTime;
  final String? endTime;
  final String? classification;
  final String? notes;
  final int? sharedWith;

  // Patient info (jika tersedia dari API)
  final String? patientName;
  final String? patientEmail;

  const MedicalRecord({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.source,
    required this.bpmData,
    required this.startTime,
    this.endTime,
    this.classification,
    this.notes,
    this.sharedWith,
    this.patientName,
    this.patientEmail,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'],
      source: json['source'] ?? 'clinic',
      bpmData:
          (json['bmp_data'] as List<dynamic>?)
              ?.map((e) => BpmDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      classification: json['classification'],
      notes: json['notes'],
      sharedWith: json['shared_with'],
      patientName: json['patient_name'] ?? json['patient']?['name'],
      patientEmail: json['patient_email'] ?? json['patient']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'source': source,
      'bmp_data': bpmData.map((e) => e.toJson()).toList(),
      'start_time': startTime,
      'end_time': endTime,
      'classification': classification,
      'notes': notes,
      'shared_with': sharedWith,
    };
  }

  /// Format waktu untuk display
  String get formattedStartTime {
    try {
      final dateTime = DateTime.parse(startTime);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return startTime;
    }
  }

  /// Durasi monitoring dalam menit
  int? get durationInMinutes {
    if (endTime == null) return null;
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime!);
      return end.difference(start).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// BPM rata-rata
  double get averageBpm {
    if (bpmData.isEmpty) return 0.0;
    final total = bpmData.fold<double>(0.0, (sum, point) => sum + point.bpm);
    return total / bpmData.length;
  }

  /// Status klasifikasi dengan warna
  ClassificationStatus get classificationStatus {
    switch (classification?.toLowerCase()) {
      case 'normal':
        return ClassificationStatus.normal;
      case 'abnormal':
        return ClassificationStatus.abnormal;
      case 'irregular':
        return ClassificationStatus.irregular;
      default:
        return ClassificationStatus.unknown;
    }
  }

  /// Source display name
  String get sourceDisplayName {
    switch (source) {
      case 'clinic':
        return 'Klinik';
      case 'self':
      case 'self_monitoring':
        return 'Mandiri';
      default:
        return source;
    }
  }
}

/// Model untuk data point BPM
class BpmDataPoint {
  final double time;
  final double bpm;

  const BpmDataPoint({required this.time, required this.bpm});

  factory BpmDataPoint.fromJson(Map<String, dynamic> json) {
    return BpmDataPoint(
      time: (json['time'] ?? 0).toDouble(),
      bpm: (json['bpm'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time, 'bpm': bpm};
  }
}

/// Enum untuk status klasifikasi
enum ClassificationStatus { normal, abnormal, irregular, unknown }

/// Extension untuk ClassificationStatus
extension ClassificationStatusExtension on ClassificationStatus {
  String get displayName {
    switch (this) {
      case ClassificationStatus.normal:
        return 'Normal';
      case ClassificationStatus.abnormal:
        return 'Abnormal';
      case ClassificationStatus.irregular:
        return 'Tidak Teratur';
      case ClassificationStatus.unknown:
        return 'Belum Dianalisis';
    }
  }

  String get colorName {
    switch (this) {
      case ClassificationStatus.normal:
        return 'green';
      case ClassificationStatus.abnormal:
        return 'red';
      case ClassificationStatus.irregular:
        return 'orange';
      case ClassificationStatus.unknown:
        return 'gray';
    }
  }
}

/// Filter untuk pencarian medical records
class MedicalRecordFilter {
  final int? patientId;
  final int? doctorId;
  final String? dateFrom;
  final String? dateTo;
  final String? classification;
  final String? source;
  final int limit;
  final int offset;

  const MedicalRecordFilter({
    this.patientId,
    this.doctorId,
    this.dateFrom,
    this.dateTo,
    this.classification,
    this.source,
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (patientId != null) params['patient_id'] = patientId.toString();
    if (doctorId != null) params['doctor_id'] = doctorId.toString();
    if (dateFrom != null) params['date_from'] = dateFrom!;
    if (dateTo != null) params['date_to'] = dateTo!;
    if (classification != null) params['classification'] = classification!;
    if (source != null) params['source'] = source!;
    params['limit'] = limit.toString();
    params['offset'] = offset.toString();

    return params;
  }

  MedicalRecordFilter copyWith({
    int? patientId,
    int? doctorId,
    String? dateFrom,
    String? dateTo,
    String? classification,
    String? source,
    int? limit,
    int? offset,
  }) {
    return MedicalRecordFilter(
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      classification: classification ?? this.classification,
      source: source ?? this.source,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
