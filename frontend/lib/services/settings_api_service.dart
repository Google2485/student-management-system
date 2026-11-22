import 'dart:convert';

import 'package:http/http.dart' as http;

class SettingsApiService {
  static const String baseUrl = 'http://localhost/SMS/EduManage/backend/api';

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _get(
    String endpoint,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/$endpoint.php'),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _put(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/settings/$endpoint.php'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(
        jsonDecode(response.body),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] != true) {
        throw Exception(result['message'] ?? 'Settings request failed');
      }

      return result;
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid server response (${response.statusCode})');
      }
      rethrow;
    }
  }

  // Profile Settings
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final result = await _get('profile', token);
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  static Future<void> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _put('profile', token, data);
  }

  // Institution Settings
  static Future<Map<String, dynamic>> getInstitution(String token) async {
    final result = await _get('institution', token);
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  static Future<void> updateInstitution(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _put('institution', token, data);
  }

  // Security Settings
  static Future<void> changePassword(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _put('password', token, data);
  }

  // Notification Settings
  static Future<Map<String, dynamic>> getNotifications(String token) async {
    final result = await _get('notifications', token);
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  static Future<void> updateNotifications(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _put('notifications', token, data);
  }

  // Appearance Settings
  static Future<Map<String, dynamic>> getPreferences(String token) async {
    final result = await _get('preferences', token);
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  static Future<void> updatePreferences(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _put('preferences', token, data);
  }
}
