import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://exora-app-admin-dashboard.onrender.com/api';

  // --------------- helpers ------------------
  static Future<Map<String, String>> headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --------------- auth ------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userId', data['user']['id']);
      await prefs.setString('userName', data['user']['full_name'] ?? '');
      await prefs.setString('userEmail', data['user']['email'] ?? '');
      return data;
    } else {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Login failed');
    }
  }

  static Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      body: jsonEncode({'fullName': name, 'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // --------------- departments & courses ---------------
  static Future<List<dynamic>> getDepartments() async {
    final authHeaders = await headers();
    final res = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load departments');
  }

 static Future<List<dynamic>> getCourses(String departmentId, {String? type}) async {
  final authHeaders = await headers();
  var url = '$baseUrl/courses?department_id=$departmentId';
  if (type != null) url += '&type=$type';
  final res = await http.get(
    Uri.parse(url),
    headers: authHeaders,
  ).timeout(const Duration(seconds: 60));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('Failed to load courses');
}

static Future<Map<String, dynamic>> getPaymentInfo() async {
  final authHeaders = await headers();
  final res = await http.get(
    Uri.parse('$baseUrl/payments/info'),
    headers: authHeaders,
  ).timeout(const Duration(seconds: 30));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('Failed to load payment info');
}

  static Future<List<dynamic>> getUserCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final authHeaders = await headers();
    final res = await http.get(
      Uri.parse('$baseUrl/courses/user/$userId'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load user courses');
  }

  static Future<List<dynamic>> getQuestions(String courseId, {String questionType = 'course'}) async {
    final authHeaders = await headers();
    final res = await http.get(
      Uri.parse('$baseUrl/questions?course_id=$courseId&question_type=$questionType'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load questions');
  }

  static Future<void> changePassword(String email, String oldPassword, String newPassword) async {
    final authHeaders = await headers();
    final res = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: authHeaders,
      body: jsonEncode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Password change failed');
    }
  }

  static Future<void> updateProfile(String userId, String fullName) async {
    final authHeaders = await headers();
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: authHeaders,
      body: jsonEncode({'full_name': fullName}),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Profile update failed');
    }
  }

  static Future<void> submitSupportTicket(String subject, String message) async {
  final authHeaders = await headers();
  final res = await http.post(
    Uri.parse('$baseUrl/support'),
    headers: authHeaders,
    body: jsonEncode({'subject': subject, 'message': message}),
  ).timeout(const Duration(seconds: 30));
  if (res.statusCode != 201) {
    throw Exception(jsonDecode(res.body)['error'] ?? 'Failed to submit ticket');
  }
}

static Future<List<dynamic>> getMySupportTickets() async {
  final authHeaders = await headers();
  final res = await http.get(
    Uri.parse('$baseUrl/support/my'),
    headers: authHeaders,
  ).timeout(const Duration(seconds: 30));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('Failed to load tickets');
}
}