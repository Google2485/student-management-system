import 'dart:convert';

import 'package:http/http.dart' as http;

class FeesApiService {
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
      throw Exception(data['message'] ?? "Something went wrong");
    }

    return data;
  }

  // Get Fee Types
  static Future<List<dynamic>> getFeeTypes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fees/types.php'),
      headers: _headers(token),
    );

    final data = _decode(response);
    return data['data'] ?? [];
  }

  // Create Fee Type
  static Future<void> createFeeType({
    required String token,
    required String name,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fees/create_type.php'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'amount': amount}),
    );

    _decode(response);
  }

  // Collect Payment
  static Future<void> collectPayment({
    required String token,
    required int studentId,
    required int feeTypeId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fees/payment.php'),
      headers: _headers(token),
      body: jsonEncode({
        'student_id': studentId,
        'fee_type_id': feeTypeId,
        'amount': amount,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
      }),
    );

    _decode(response);
  }

  // Payment History
  static Future<List<dynamic>> getPaymentHistory(
    String token, {
    int? studentId,
  }) async {
    final uri = studentId == null
        ? Uri.parse('$baseUrl/fees/history.php')
        : Uri.parse('$baseUrl/fees/history.php?student_id=$studentId');

    final response = await http.get(uri, headers: _headers(token));

    final data = _decode(response);
    return data['data'] ?? [];
  }

  // Fee Summary
  static Future<Map<String, dynamic>> getFeeSummary(
    String token, {
    int? studentId,
  }) async {
    final uri = studentId == null
        ? Uri.parse('$baseUrl/fees/summary.php')
        : Uri.parse('$baseUrl/fees/summary.php?student_id=$studentId');

    final response = await http.get(uri, headers: _headers(token));

    final data = _decode(response);
    return data['data'] ?? {};
  }
}
