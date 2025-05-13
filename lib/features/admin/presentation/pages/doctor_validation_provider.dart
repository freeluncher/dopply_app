import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final doctorValidationCountProvider = FutureProvider<int>((ref) async {
  final response = await http.get(
    Uri.parse('https://dopply.my.id/v1/admin/doctor/validation-requests/count'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is Map && data['pending_validation'] != null) {
      return data['pending_validation'] as int;
    }
  }
  return 0;
});
