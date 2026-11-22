import 'dart:convert';

import 'package:http/http.dart' as http;

class ReportsApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Future<Map<String, dynamic>> getSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/summary.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> result = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(result['message'] ?? 'Unable to load reports data');
    }

    return Map<String, dynamic>.from(result['data'] ?? {});
  }
}
