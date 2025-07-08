// =============================================================================
// Fetal Monitoring Models
//
// Data models for fetal heart rate monitoring system
// =============================================================================

import 'package:equatable/equatable.dart';

// Monitoring Types
enum MonitoringType {
  clinic, // Doctor-assisted monitoring at clinic
  home, // Patient self-monitoring at home
}

// Monitoring Session Model
class FetalMonitoringSession extends Equatable {
  final String id;
  final int? patientId;
  final int? doctorId;
  final MonitoringType type;
  final int gestationalAge;
  final DateTime startTime;
  final DateTime? endTime;
  final List<FetalHeartRateReading> readings;
  final String? notes;
  final String? doctorNotes;
  final bool isSharedWithDoctor;
  final FetalMonitoringResult? result;

  const FetalMonitoringSession({
    required this.id,
    this.patientId,
    this.doctorId,
    required this.type,
    required this.gestationalAge,
    required this.startTime,
    this.endTime,
    this.readings = const [],
    this.notes,
    this.doctorNotes,
    this.isSharedWithDoctor = false,
    this.result,
  });

  FetalMonitoringSession copyWith({
    String? id,
    int? patientId,
    int? doctorId,
    MonitoringType? type,
    int? gestationalAge,
    DateTime? startTime,
    DateTime? endTime,
    List<FetalHeartRateReading>? readings,
    String? notes,
    String? doctorNotes,
    bool? isSharedWithDoctor,
    FetalMonitoringResult? result,
  }) {
    return FetalMonitoringSession(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      type: type ?? this.type,
      gestationalAge: gestationalAge ?? this.gestationalAge,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      readings: readings ?? this.readings,
      notes: notes ?? this.notes,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      isSharedWithDoctor: isSharedWithDoctor ?? this.isSharedWithDoctor,
      result: result ?? this.result,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'monitoring_type': type.name,
    'gestational_age': gestationalAge,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'readings': readings.map((r) => r.toJson()).toList(),
    'notes': notes,
    'doctor_notes': doctorNotes,
    'shared_with_doctor': isSharedWithDoctor,
    'result': result?.toJson(),
  };

  factory FetalMonitoringSession.fromJson(Map<String, dynamic> json) {
    return FetalMonitoringSession(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      type: MonitoringType.values.firstWhere(
        (t) => t.name == json['monitoring_type'],
        orElse: () => MonitoringType.home,
      ),
      gestationalAge: json['gestational_age'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      readings:
          (json['readings'] as List?)
              ?.map((r) => FetalHeartRateReading.fromJson(r))
              .toList() ??
          [],
      notes: json['notes'],
      doctorNotes: json['doctor_notes'],
      isSharedWithDoctor: json['shared_with_doctor'] ?? false,
      result:
          json['result'] != null
              ? FetalMonitoringResult.fromJson(json['result'])
              : null,
    );
  }

  bool get isCompleted => endTime != null;
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    type,
    gestationalAge,
    startTime,
    endTime,
    readings,
    notes,
    doctorNotes,
    isSharedWithDoctor,
    result,
  ];
}

// Individual Heart Rate Reading
class FetalHeartRateReading extends Equatable {
  final DateTime timestamp;
  final int bpm;
  final double? signalQuality;
  final String classification;

  const FetalHeartRateReading({
    required this.timestamp,
    required this.bpm,
    this.signalQuality,
    required this.classification,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'bpm': bpm,
    'signal_quality': signalQuality,
    'classification': classification,
  };

  factory FetalHeartRateReading.fromJson(Map<String, dynamic> json) {
    return FetalHeartRateReading(
      timestamp: DateTime.parse(json['timestamp']),
      bpm: json['bpm'],
      signalQuality: json['signal_quality']?.toDouble(),
      classification: json['classification'],
    );
  }

  @override
  List<Object?> get props => [timestamp, bpm, signalQuality, classification];
}

// Monitoring Result/Classification
class FetalMonitoringResult extends Equatable {
  final String overallClassification; // normal, concerning, abnormal
  final double averageBPM;
  final double? baselineVariability;
  final List<String> findings;
  final List<String> recommendations;
  final String riskLevel; // low, medium, high

  const FetalMonitoringResult({
    required this.overallClassification,
    required this.averageBPM,
    this.baselineVariability,
    required this.findings,
    required this.recommendations,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() => {
    'overall_classification': overallClassification,
    'average_bpm': averageBPM,
    'baseline_variability': baselineVariability,
    'findings': findings,
    'recommendations': recommendations,
    'risk_level': riskLevel,
  };

  factory FetalMonitoringResult.fromJson(Map<String, dynamic> json) {
    return FetalMonitoringResult(
      overallClassification: json['overall_classification'],
      averageBPM: json['average_bpm']?.toDouble() ?? 0.0,
      baselineVariability: json['baseline_variability']?.toDouble(),
      findings: List<String>.from(json['findings'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      riskLevel: json['risk_level'],
    );
  }

  @override
  List<Object?> get props => [
    overallClassification,
    averageBPM,
    baselineVariability,
    findings,
    recommendations,
    riskLevel,
  ];
}

// Patient Pregnancy Info
class PatientPregnancyInfo extends Equatable {
  final int patientId;
  final int gestationalAge; // in weeks
  final DateTime expectedDueDate;
  final DateTime lastMenstrualPeriod;
  final bool isHighRisk;
  final List<String> riskFactors;
  final String? notes;

  const PatientPregnancyInfo({
    required this.patientId,
    required this.gestationalAge,
    required this.expectedDueDate,
    required this.lastMenstrualPeriod,
    this.isHighRisk = false,
    this.riskFactors = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'gestational_age': gestationalAge,
    'expected_due_date': expectedDueDate.toIso8601String(),
    'last_menstrual_period': lastMenstrualPeriod.toIso8601String(),
    'is_high_risk': isHighRisk,
    'risk_factors': riskFactors,
    'notes': notes,
  };

  factory PatientPregnancyInfo.fromJson(Map<String, dynamic> json) {
    return PatientPregnancyInfo(
      patientId: json['patient_id'],
      gestationalAge: json['gestational_age'],
      expectedDueDate: DateTime.parse(json['expected_due_date']),
      lastMenstrualPeriod: DateTime.parse(json['last_menstrual_period']),
      isHighRisk: json['is_high_risk'] ?? false,
      riskFactors: List<String>.from(json['risk_factors'] ?? []),
      notes: json['notes'],
    );
  }

  String get trimesterDescription {
    if (gestationalAge <= 12) return 'First Trimester';
    if (gestationalAge <= 28) return 'Second Trimester';
    return 'Third Trimester';
  }

  int get weeksRemaining {
    final daysRemaining = expectedDueDate.difference(DateTime.now()).inDays;
    return (daysRemaining / 7).ceil();
  }

  @override
  List<Object?> get props => [
    patientId,
    gestationalAge,
    expectedDueDate,
    lastMenstrualPeriod,
    isHighRisk,
    riskFactors,
    notes,
  ];
}
