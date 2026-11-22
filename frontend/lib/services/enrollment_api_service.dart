import 'dart:convert';

import 'package:http/http.dart' as http;

class EnrollmentApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Future<List<Map<String, dynamic>>> getEnrollment(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/enrollment.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> result = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(result['message'] ?? 'Unable to load enrollment data');
    }

    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }
}
