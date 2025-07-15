import 'package:flutter/material.dart';
import 'package:dopply_app/core/api_client.dart';
import 'package:dopply_app/models/patient.dart';

class ShareDoctorScreen extends StatefulWidget {
  const ShareDoctorScreen({Key? key}) : super(key: key);

  @override
  State<ShareDoctorScreen> createState() => _ShareDoctorScreenState();
}

class _ShareDoctorScreenState extends State<ShareDoctorScreen> {
  List<Patient> _doctors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllDoctors();
  }

  Future<void> _fetchAllDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioResponse = await ApiClient().dio.get('/api/v1/user/all-doctors');
      final data = dioResponse.data;
      if (data != null && data is List) {
        setState(() {
          _doctors =
              data.map<Patient>((item) {
                return Patient(
                  id: item['id'],
                  name: item['name'] ?? '',
                  email: item['email'] ?? '',
                  gestationalAge: null,
                  hpht: null,
                );
              }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Data dokter tidak valid.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil daftar dokter: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Dokter Tujuan')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(doctor.name),
                    subtitle: Text(doctor.email),
                    onTap: () {
                      // TODO: Implementasi share hasil monitoring ke dokter ini
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pilih dokter: ${doctor.name}')),
                      );
                    },
                  );
                },
              ),
    );
  }
}
