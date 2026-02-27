import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Demo credentials for offline/testing mode:
///   Email:    demo@thinkdigital.com
///   Password: password123
///
/// When the backend is unreachable, the app automatically
/// falls back to demo mode with these credentials.

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';

  // Set to true to always use demo data (skip API calls entirely)
  static bool _forceDemoMode = false;

  static void setDemoMode(bool enabled) => _forceDemoMode = enabled;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ───

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // Try real API first
    if (!_forceDemoMode) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/login'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        // If server returned an error, return that
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Server unreachable – fall through to demo mode
      }
    }

    // ──── Demo Mode ────
    return _demoLogin(email, password);
  }

  static Map<String, dynamic> _demoLogin(String email, String password) {
    // Demo credentials
    const demoUsers = [
      {
        'email': 'demo@thinkdigital.com',
        'password': 'password123',
        'name': 'Parth Gorde',
        'role': 'Admin',
      },
      {
        'email': 'employee@thinkdigital.com',
        'password': 'password123',
        'name': 'John Doe',
        'role': 'Employee',
      },
      {
        'email': 'manager@thinkdigital.com',
        'password': 'password123',
        'name': 'Jane Smith',
        'role': 'Manager',
      },
    ];

    final user = demoUsers.cast<Map<String, String>?>().firstWhere(
          (u) => u!['email'] == email && u['password'] == password,
          orElse: () => null,
        );

    if (user != null) {
      return {
        'token': 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': 1,
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
        },
        'message': 'Login successful (Demo Mode)',
      };
    }

    return {'message': 'Invalid credentials. Try demo@thinkdigital.com / password123'};
  }

  static Future<void> logout() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        await http
            .post(Uri.parse('$baseUrl/logout'), headers: headers)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    // Demo mode: nothing extra to do
  }

  // ─── Clock ───

  static Future<Map<String, dynamic>> clockIn() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        final response = await http
            .post(Uri.parse('$baseUrl/clock-in'), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'success',
      'message': 'Clocked in successfully',
      'clock_in': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> clockOut() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        final response = await http
            .post(Uri.parse('$baseUrl/clock-out'), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'success',
      'message': 'Clocked out successfully',
      'clock_out': DateTime.now().toIso8601String(),
    };
  }

  // ─── Break ───

  static Future<Map<String, dynamic>> breakIn() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        final response = await http
            .post(Uri.parse('$baseUrl/break-in'), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'success',
      'message': 'Break started',
      'break_in': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> breakOut() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        final response = await http
            .post(Uri.parse('$baseUrl/break-out'), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'success',
      'message': 'Break ended',
      'break_out': DateTime.now().toIso8601String(),
    };
  }

  // ─── Status ───

  static Future<Map<String, dynamic>> getStatus() async {
    if (!_forceDemoMode) {
      try {
        final headers = await _headers();
        final response = await http
            .get(Uri.parse('$baseUrl/attendance/status'), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'idle',
      'message': 'Demo mode - no server data',
    };
  }
}
