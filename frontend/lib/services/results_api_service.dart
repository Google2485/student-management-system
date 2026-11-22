import 'dart:convert';

import 'package:http/http.dart' as http;

class ResultsApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}

    throw Exception('Invalid server response (${response.statusCode})');
  }

  static Future<List<dynamic>> getResults(
    String token, {
    int? studentId,
    String? examName,
  }) async {
    final query = <String, String>{};

    if (studentId != null) {
      query['student_id'] = studentId.toString();
    }

    if (examName != null && examName.trim().isNotEmpty) {
      query['exam_name'] = examName.trim();
    }

    final uri = Uri.parse('$baseUrl/results/read.php')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return List<dynamic>.from(data['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Unable to load results');
  }

  static Future<void> createResult(
    String token,
    Map<String, dynamic> result,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/results/create.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(result),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Result creation failed');
    }
  }

  static Future<void> updateResult(
    String token,
    Map<String, dynamic> result,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/results/update.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(result),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Result update failed');
    }
  }

  static Future<void> deleteResult(String token, int id) async {
    final uri = Uri.parse('$baseUrl/results/delete.php')
        .replace(queryParameters: {'id': id.toString()});

    final response = await http
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Result deletion failed');
    }
  }
}
