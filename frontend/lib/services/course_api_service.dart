import 'dart:convert';

import 'package:http/http.dart' as http;

class CourseApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Invalid JSON response.
    }

    throw Exception('Invalid server response (${response.statusCode})');
  }

  // Get all departments
  static Future<List<dynamic>> getDepartments(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/departments.php'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return List<dynamic>.from(data['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Unable to load departments');
  }

  // Create department
  static Future<void> createDepartment(String token, String name) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/create_department.php'),
          headers: _headers(token),
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Department creation failed');
    }
  }

  // Update department
  static Future<void> updateDepartment(
    String token,
    int id,
    String name,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/update_department.php'),
          headers: _headers(token),
          body: jsonEncode({'id': id, 'name': name}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Department update failed');
    }
  }

  // Delete department
  static Future<void> deleteDepartment(String token, int id) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/delete_department.php'),
          headers: _headers(token),
          body: jsonEncode({'id': id}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Department deletion failed');
    }
  }

  // Get all courses
  static Future<List<dynamic>> getCourses(String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/courses/list.php'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return List<dynamic>.from(data['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Unable to load courses');
  }

  // Create course
  static Future<void> createCourse(
    String token,
    Map<String, dynamic> course,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/create.php'),
          headers: _headers(token),
          body: jsonEncode(course),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Course creation failed');
    }
  }

  // Update course
  static Future<void> updateCourse(
    String token,
    Map<String, dynamic> course,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/update.php'),
          headers: _headers(token),
          body: jsonEncode(course),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Course update failed');
    }
  }

  // Delete course
  static Future<void> deleteCourse(String token, int id) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/delete.php'),
          headers: _headers(token),
          body: jsonEncode({'id': id}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Course deletion failed');
    }
  }
}
