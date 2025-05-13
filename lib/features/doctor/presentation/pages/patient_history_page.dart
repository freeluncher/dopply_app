import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dopply_app/features/doctor/data/services/record_api_service.dart';

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({Key? key}) : super(key: key);

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _searchController.addListener(_onSearch);
  }

  Future<void> _fetchRecords() async {
    setState(() => isLoading = true);
    final api = RecordApiService();
    final records = await api.fetchRecords();
    allRecords =
        records
            .map(
              (r) => {
                'id': r['id']?.toString() ?? '-',
                'name': 'Patient #${r['patient_id']?.toString() ?? '-'}',
                'summary': r['classification'] ?? r['notes'] ?? '-',
              },
            )
            .toList();
    filteredRecords = allRecords;
    setState(() => isLoading = false);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredRecords =
          allRecords.where((record) {
            return record['name']!.toLowerCase().contains(query) ||
                record['id']!.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari pasien (nama atau ID)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredRecords.isEmpty
                      ? const Center(child: Text('Tidak ada riwayat ditemukan'))
                      : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            child: ListTile(
                              title: Text(record['name'] ?? '-'),
                              subtitle: Text(record['summary'] ?? ''),
                              trailing: Text('#${record['id']}'),
                              onTap: () {
                                context.push(
                                  '/doctor/patient-history/${record['id']}',
                                  extra: {
                                    'name': record['name'],
                                    'summary': record['summary'],
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
