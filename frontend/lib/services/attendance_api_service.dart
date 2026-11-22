import 'dart:convert';

import 'package:http/http.dart' as http;

class AttendanceApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Something went wrong');
    }

    return data;
  }

  // Get attendance list by date
  static Future<List<dynamic>> getAttendance(String token, String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/list.php?date=$date'),
      headers: _headers(token),
    );

    final data = _decode(response);

    return data['data'] ?? [];
  }

  // Mark attendance
  static Future<void> markAttendance({
    required String token,
    required int studentId,
    required String date,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/mark.php'),
      headers: _headers(token),
      body: jsonEncode({
        'student_id': studentId,
        'attendance_date': date,
        'status': status,
      }),
    );

    _decode(response);
  }

  // Update attendance
  static Future<void> updateAttendance({
    required String token,
    required int attendanceId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/update.php'),
      headers: _headers(token),
      body: jsonEncode({'id': attendanceId, 'status': status}),
    );

    _decode(response);
  }

  // Get student attendance report
  static Future<Map<String, dynamic>> getReport({
    required String token,
    required int studentId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/report.php?student_id=$studentId'),
      headers: _headers(token),
    );

    return _decode(response);
  }
}
