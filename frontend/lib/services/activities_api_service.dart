import 'dart:convert';

import 'package:http/http.dart' as http;

class ActivitiesApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Future<List<Map<String, dynamic>>> getActivities(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/activities.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> result = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(result['message'] ?? 'Unable to load recent activities');
    }

    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }
}
