import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://exora-app-admin-dashboard.onrender.com/api';

  // --------------- helpers ------------------
  static Future<Map<String, String>> _headers() async {
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
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userId', data['user']['id']);
      return data; // { token, user: { id, email, role } }
    } else {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Login failed');
    }
  }

  static Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      body: jsonEncode({'fullName': name, 'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Registration failed');
    }
  }

  // --------------- departments & courses ---------------
  static Future<List<dynamic>> getDepartments() async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load departments');
  }

  static Future<List<dynamic>> getCourses(String departmentId) async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/courses?department_id=$departmentId'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load courses');
  }

  // Get courses for current user with lock status
  static Future<List<dynamic>> getUserCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/courses/user/$userId'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load user courses');
  }

  // --------------- questions ---------------
  static Future<List<dynamic>> getQuestions(String courseId) async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$baseUrl/questions?course_id=$courseId'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load questions');
  }
}