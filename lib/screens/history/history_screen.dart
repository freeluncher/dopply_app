import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dopply_app/core/storage.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/core/routes.dart';

class MonitoringResult {
  final int id;
  final String patientName;
  final String classification;
  final double averageBpm;
  final int gestationalAge;
  final String notes;
  final String doctorNotes;

  MonitoringResult({
    required this.id,
    required this.patientName,
    required this.classification,
    required this.averageBpm,
    required this.gestationalAge,
    required this.notes,
    required this.doctorNotes,
  });

  factory MonitoringResult.fromJson(Map<String, dynamic> json) {
    return MonitoringResult(
      id: json['id'],
      patientName: json['patient_name'] ?? '',
      classification: json['classification'] ?? '',
      averageBpm: (json['average_bpm'] ?? 0).toDouble(),
      gestationalAge: json['gestational_age'] ?? 0,
      notes: json['notes'] ?? '',
      doctorNotes: json['doctor_notes'] ?? '',
    );
  }
}

Future<List<MonitoringResult>> fetchMonitoringHistory(
  String jwtToken, {
  int? patientId,
  int skip = 0,
  int limit = 20,
}) async {
  final uri = Uri.parse(
    'https://dopply.my.id/api/v1/monitoring/history',
  ).replace(
    queryParameters: {
      if (patientId != null) 'patient_id': patientId.toString(),
      'skip': skip.toString(),
      'limit': limit.toString(),
    },
  );

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    },
  );

  final jsonResponse = json.decode(response.body);
  if (jsonResponse['status'] == 200 && jsonResponse['data'] is List) {
    return (jsonResponse['data'] as List)
        .map((item) => MonitoringResult.fromJson(item))
        .toList();
  } else {
    // Handle error, show message if needed
    return [];
  }
}

class HistoryScreen extends StatefulWidget {
  final int? patientId;

  const HistoryScreen({this.patientId, Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _role;
  late Future<List<MonitoringResult>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _futureHistory = _getHistory();
    _getRole();
  }

  Future<void> _getRole() async {
    final userJson = await StorageService.getUserData();
    if (userJson != null && userJson.isNotEmpty) {
      final userMap = jsonDecode(userJson);
      setState(() {
        _role = userMap['role'];
      });
    }
  }

  Future<List<MonitoringResult>> _getHistory() async {
    final token = await StorageService.getToken();
    final userJson = await StorageService.getUserData();
    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      return [];
    }
    final userMap = jsonDecode(userJson);
    final userId = userMap['id'];
    final role = userMap['role'];
    final allResults = await fetchMonitoringHistory(token);
    // Filter sesuai role dan user id
    if (role == 'patient') {
      return allResults.where((r) => r.id == userId).toList();
    } else if (role == 'doctor') {
      // Asumsikan backend mengirim doctor_id di field tertentu, misal doctor_id
      // Jika tidak ada, fallback ke id
      return allResults.where((r) => r.id == userId).toList();
    } else {
      // Admin: tampilkan semua
      return allResults;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Dashboard',
          onPressed: () {
            if (_role != null) {
              AppNavigation.toDashboard(context, _role!);
            } else {
              context.go('/splash');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () {
              if (_role != null) {
                AppNavigation.toDashboard(context, _role!);
              } else {
                context.go('/splash');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MonitoringResult>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data'));
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat monitoring'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final result = history[index];
              return ListTile(
                title: Text(result.patientName),
                subtitle: Text(
                  'Klasifikasi: ${result.classification} | BPM: ${result.averageBpm}',
                ),
                trailing: Text('Usia: ${result.gestationalAge} minggu'),
                onTap: () {
                  _showDetailDialog(context, result);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, MonitoringResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detail Monitoring'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nama Pasien: ${result.patientName}'),
                Text('Klasifikasi: ${result.classification}'),
                Text('Rata-rata BPM: ${result.averageBpm}'),
                Text('Usia Kandungan: ${result.gestationalAge} minggu'),
                if (result.notes.isNotEmpty) Text('Catatan: ${result.notes}'),
                if (result.doctorNotes.isNotEmpty)
                  Text('Catatan Dokter: ${result.doctorNotes}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}
