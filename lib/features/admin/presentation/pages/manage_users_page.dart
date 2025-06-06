import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_validation_provider.dart';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';

final doctorValidationListProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final localDataSource = AuthLocalDataSource();
    final token = await localDataSource.getToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('https://dopply.my.id/v1/admin/doctor/validation-requests'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  },
);

class ManageUsersPage extends ConsumerWidget {
  const ManageUsersPage({Key? key}) : super(key: key);

  Future<void> validateDoctor(
    BuildContext context,
    WidgetRef ref,
    int doctorId,
  ) async {
    final localDataSource = AuthLocalDataSource();
    final token = await localDataSource.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token admin tidak ditemukan!')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://dopply.my.id/v1/admin/doctor/validate/$doctorId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokter berhasil divalidasi!')),
        );
        ref.refresh(doctorValidationListProvider);
        ref.refresh(doctorValidationCountProvider);
      } else {
        String message = 'Unknown error';
        try {
          final data = jsonDecode(response.body);
          message = data['message'] ?? message;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal validasi dokter: $message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal validasi dokter: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorListAsync = ref.watch(doctorValidationListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User - Validasi Dokter')),
      body: doctorListAsync.when(
        data:
            (doctors) =>
                doctors.isEmpty
                    ? const Center(
                      child: Text('Tidak ada dokter yang menunggu validasi.'),
                    )
                    : ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(doctor['name'] ?? '-'),
                            subtitle: Text('Email: ${doctor['email'] ?? '-'}'),
                            trailing: ElevatedButton(
                              onPressed:
                                  () => validateDoctor(
                                    context,
                                    ref,
                                    doctor['doctor_id'],
                                  ),
                              child: const Text('Validasi'),
                            ),
                          ),
                        );
                      },
                    ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
      ),
    );
  }
}
