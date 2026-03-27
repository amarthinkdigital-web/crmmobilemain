import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live Backend: http://192.168.1.12:8000/api
///
/// Laravel Sanctum Routes:
///   POST  /login                    → { email, password, device_name }
///   POST  /logout                   → Bearer token required
///   GET   /user                     → Bearer token required
///   POST  /attendance/clock-in      → Bearer token required
///   POST  /attendance/clock-out     → Bearer token required
///   POST  /attendance/break-in      → Bearer token required
///   POST  /attendance/break-out     → Bearer token required

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.12:8000/api';

  static String get _deviceName {
    if (kIsWeb) return 'FlutterWeb';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'FlutterApp';
    }
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Logs in via Laravel Sanctum.
  /// Sends: email, password, device_name
  /// On network error returns: { 'error': true, 'message': '...' }
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'login_id': email,
              'password': password,
              'device_name': _deviceName,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final body = response.body;
      if (body.isEmpty) {
        return {'error': true, 'message': 'Server returned an empty response.'};
      }

      final data = jsonDecode(body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sanctum can return a plain token string
        if (data is String && data.isNotEmpty) {
          final user = await _fetchUser(data);
          return {'token': data, 'user': user};
        }
        // Or a JSON object
        return data as Map<String, dynamic>;
      }

      // Server returned validation/auth error (422, 401, etc.)
      if (data is Map) {
        final msg =
            data['message'] ??
            data['error'] ??
            'Login failed (${response.statusCode})';
        return {'error': true, 'message': msg.toString()};
      }

      return {
        'error': true,
        'message': 'Login failed (${response.statusCode})',
      };
    } on SocketException {
      return {
        'error': true,
        'message':
            'Cannot reach the server. Make sure you are on the same network as the backend (${_hostOnly()}).',
      };
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('timed out') || msg.contains('TimeoutException')) {
        return {
          'error': true,
          'message': 'Connection timed out. Server may be down or unreachable.',
        };
      }
      return {'error': true, 'message': 'Connection error: $msg'};
    }
  }

  static String _hostOnly() {
    try {
      return Uri.parse(baseUrl).host;
    } catch (_) {
      return baseUrl;
    }
  }

  /// Fetches authenticated user after plain-token login
  static Future<Map<String, dynamic>> _fetchUser(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'login_id': email,
              'password': password,
              'password_confirmation': password,
              'device_name': _deviceName,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      return {
        'error': true,
        'message': 'Cannot reach the server. Check your network connection.',
      };
    } catch (_) {
      return {'error': true, 'message': 'Registration failed. Try again.'};
    }
  }

  static Future<void> logout() async {
    try {
      final headers = await _headers();
      await http
          .post(Uri.parse('$baseUrl/logout'), headers: headers)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
    // Always clear local auth regardless of server response
  }

  // ─── Attendance ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> clockIn() async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/attendance/clock-in'), headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to clock in',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> clockOut() async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/attendance/clock-out'), headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to clock out',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAllAttendances({String? date, String? userId, String? startDate, String? endDate}) async {
    try {
      final headers = await _headers();
      String url = '$baseUrl/attendance/all-attendances';
      List<String> params = [];
      if (date != null) params.add('date=$date');
      if (userId != null) params.add('user_id=$userId');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        List list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is List) {
            list = data['data'];
          } else if (data['data'] is Map && data['data']['data'] is List) {
            list = data['data']['data'];
          } else {
            // Find any list in values
            for (var val in data.values) {
              if (val is List) {
                list = val;
                break;
              }
            }
          }
        }
        return {'error': false, 'data': list, 'raw': data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to load all attendances',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getMyAttendance() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/attendance/my-attendance'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        List list = [];
        if (data is Map && data['data'] is List) {
          list = data['data'];
        } else if (data is List) {
          list = data;
        } else {
          // Fallback extraction
          for (var val in data.values) {
            if (val is List) {
              list = val;
              break;
            }
          }
        }
        return {'error': false, 'data': list, 'raw': data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to load my attendance',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final res = await getMyAttendance();
      if (res['error'] == false) {
        final List list = res['data'] ?? [];
        if (list.isNotEmpty) {
          // Trust the first record (most recent) if it's NOT clocked out
          // or if its date component matches what we consider today.
          final first = list.first;
          
          // If active shift exists, it should be the one.
          if (first['clock_out'] == null) {
             return {'error': false, 'data': first};
          }

          final now = DateTime.now();
          final String recordDateStr = first['date']?.toString() ?? '';
          final dt = DateTime.parse(recordDateStr).toLocal();
          final todayStr = DateFormat('yyyy-MM-dd').format(now);
          final recordDateComp = DateFormat('yyyy-MM-dd').format(dt);
          
          if (recordDateComp == todayStr) {
            return {'error': false, 'data': first};
          }
        }
        return {'error': false, 'data': null};
      }
      return res;
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // ─── Break ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> breakIn() async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/attendance/break-in'), headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to start break',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> breakOut() async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/attendance/break-out'), headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to end break',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }


  static Future<Map<String, dynamic>> submitCorrection({
    required String date,
    required String clockIn,
    required String clockOut,
    required String reason,
  }) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$baseUrl/attendance/correction/requests'),
            headers: headers,
            body: jsonEncode({
              'date': date,
              'clock_in': clockIn,
              'clock_out': clockOut,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final dynamic decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to submit correction',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getMyCorrections() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/attendance/correction/my-requests'), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        // Doc says data['data'] contains the paginated object, so data['data']['data'] is the list
        return {'error': false, 'data': data['data']['data'] ?? []};
      }
    } catch (_) {}
    return {'error': true, 'message': 'Failed to load corrections'};
  }

  static Future<Map<String, dynamic>> getAdminCorrections({String status = 'pending', String? search}) async {
    try {
      final headers = await _headers();
      String url = '$baseUrl/attendance/correction/admin/requests?status=$status';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Assuming same paginated structure or flat list
        return {'error': false, 'data': data['data']['data'] ?? data['data'] ?? []};
      }
    } catch (_) {}
    return {'error': true, 'message': 'Failed to load admin corrections'};
  }

  static Future<Map<String, dynamic>> updateCorrectionStatus(int id, String status, String remark) async {
    try {
      final headers = await _headers();
      // Try to determine if we are manager or admin from token/shared_prefs or just try the admin route
      // and fallback if needed. Usually, the backend detects role.
      final response = await http
          .post(
            Uri.parse('$baseUrl/attendance/correction/admin/requests/$id/status'),
            headers: headers,
            body: jsonEncode({
              'status': status,
              'admin_remark': remark,
            }),
          )
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'error': false, 'message': data['message']};
      }
      return {'error': true, 'message': data['message'] ?? 'Failed to update status'};
    } catch (_) {}
    return {'error': true, 'message': 'Failed to update status'};
  }

  static Future<Map<String, dynamic>> getManagerCorrections({String status = 'pending'}) async {
    try {
      final headers = await _headers();
      // Assume manager has their own endpoint for their team
      String url = '$baseUrl/attendance/correction/manager/requests?status=$status';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data['data']['data'] ?? data['data'] ?? []};
      }
    } catch (_) {}
    return {'error': true, 'message': 'Failed to load manager corrections'};
  }

  // ─── Manager Profiles ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getManagerProfiles() async {
    try {
      final headers = await _headers();
      // Handle potential prefix or exact base url match.
      final response = await http
          .get(Uri.parse('$baseUrl/manager-profiles'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Handle paginated responses as well as standard ones
        final dynamic pagedData = data['data'];
        List list = [];
        if (pagedData is List) {
          list = pagedData;
        } else if (pagedData is Map && pagedData['data'] is List) {
          // some apis return paginate data inside data: { data: [] }
          list = pagedData['data'];
        } else if (data is List) {
          list = data;
        }
        return {'error': false, 'data': list};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to load manager profiles',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ─── Employee Profiles ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEmployeeProfiles() async {
    try {
      final headers = await _headers();
      // Handle potential prefix or exact base url match.
      final response = await http
          .get(Uri.parse('$baseUrl/employee-profiles'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Handle paginated responses as well as standard ones
        final dynamic pagedData = data['data'];
        List list = [];
        if (pagedData is List) {
          list = pagedData;
        } else if (pagedData is Map && pagedData['data'] is List) {
          // some apis return paginate data inside data: { data: [] }
          list = pagedData['data'];
        } else if (data is List) {
          list = data;
        }
        return {'error': false, 'data': list};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to load employee profiles',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ─── Departments ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDepartments() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/departments'), headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Handle both direct list or wrapped data object
        final List list = data is List ? data : (data['data'] ?? []);
        return {'error': false, 'data': list};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to load departments',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createDepartment(String name) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$baseUrl/departments'),
            headers: headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to create department',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateDepartment(
    int id,
    String name,
  ) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(
            Uri.parse('$baseUrl/departments/$id'),
            headers: headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, ...data};
      }
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to update department',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteDepartment(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/departments/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'error': false};
      }
      final data = jsonDecode(response.body);
      return {
        'error': true,
        'message': data['message'] ?? 'Failed to delete department',
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }
  // ─── Leave Management ──────────────────────────────────────────────────────

  // Manager Leaves
  static Future<Map<String, dynamic>> getManagerLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': _extractList(data)};
      }
      return {'error': true, 'message': data['message'] ?? 'Failed to load manager leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitManagerLeave(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/manager/leaves'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      
      String errorMsg = data['message'] ?? 'Failed to submit leave';
      if (data['errors'] != null && data['errors'] is Map) {
        final Map errors = data['errors'];
        errorMsg = errors.values.map((v) => v is List ? v.join('\n') : v.toString()).join('\n');
      }
      return {'error': true, 'message': errorMsg};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getManagerTeamLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/team-leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load team leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setManagerTeamLeaveStatus(int id, String status, {String? leaveType, String? reason}) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'status': status,
        'leave_status': status,
        'leave': status,
        'id': id,
        'leave_id': id,
        'leave_type': leaveType ?? 'Leave',
        if (reason != null && reason.isNotEmpty) 'reject_reason': reason,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      final response = await http
          .post(Uri.parse('$baseUrl/manager/team-leaves/$id/approve'), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAdminManagerLeaveRequests() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/manager-leave-requests'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load admin manager leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setAdminManagerLeaveStatus(int id, String status, {String? leaveType, String? reason}) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'status': status,
        'leave_status': status,
        'leave': status,
        'id': id,
        'leave_id': id,
        'leave_type': leaveType ?? 'Leave',
        if (reason != null && reason.isNotEmpty) 'reject_reason': reason,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      final response = await http
          .post(Uri.parse('$baseUrl/manager/manager-leave-requests/$id/approve'), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Employee Leaves
  static Future<Map<String, dynamic>> getEmployeeLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load employee leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitEmployeeLeave(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/employee/leaves'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      
      String errorMsg = data['message'] ?? 'Failed to submit leave';
      if (data['errors'] != null && data['errors'] is Map) {
        final Map errors = data['errors'];
        errorMsg = errors.values.map((v) => v is List ? v.join('\n') : v.toString()).join('\n');
      }
      return {'error': true, 'message': errorMsg};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAllEmployeeLeaveRequests() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/leave-requests'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load staff leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> getAdminEmployeeLeaveRequests() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/admin-leave-requests'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load admin leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setEmployeeLeaveStatus(int id, String status, {String? leaveType, String? reason}) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'status': status,
        'leave_status': status,
        'leave': status,
        'id': id,
        'leave_id': id,
        'leave_type': leaveType ?? 'Leave',
        if (reason != null && reason.isNotEmpty) 'reject_reason': reason,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      final response = await http
          .post(Uri.parse('$baseUrl/employee/leave-requests/$id/approve'), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ─── Daily Worksheets ───────────────────────────────────────────────────

  // 1. Employee Daily Worksheets
  static Future<Map<String, dynamic>> getEmployeeDailyWorksheets() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/daily-worksheets'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load worksheets'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitEmployeeDailyWorksheet(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/employee/daily-worksheets'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      
      String errorMsg = data['message'] ?? 'Failed to submit worksheet';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first.toString();
          } else {
            errorMsg = firstError.toString();
          }
        }
      }
      return {'error': true, 'message': errorMsg};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getEmployeeDailyWorksheetDetails(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/daily-worksheets/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': data};
      return {'error': true, 'message': data['message'] ?? 'Failed to load worksheet details'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateEmployeeDailyWorksheet(int id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl/employee/daily-worksheets/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update worksheet'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // 2. Manager Daily Worksheets
  static Future<Map<String, dynamic>> getManagerDailyWorksheets() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/daily-worksheets'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load manager worksheets'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitManagerDailyWorksheet(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/manager/daily-worksheets'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      
      String errorMsg = data['message'] ?? 'Failed to submit manager worksheet';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first.toString();
          } else {
            errorMsg = firstError.toString();
          }
        }
      }
      return {'error': true, 'message': errorMsg};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getManagerDailyWorksheetDetails(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/daily-worksheets/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': data};
      return {'error': true, 'message': data['message'] ?? 'Failed to load manager worksheet details'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateManagerDailyWorksheet(int id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl/manager/daily-worksheets/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update manager worksheet'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // 3. Team Leader Review APIs
  static Future<Map<String, dynamic>> getTeamWorksheets() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/team-worksheets'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load team worksheets'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> reviewTeamWorksheet(int id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/team-worksheets/$id/review'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to review team worksheet'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // 4. Admin Daily Worksheet APIs
  static Future<Map<String, dynamic>> getAdminDailyWorksheets() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/admin/daily-worksheets'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load admin worksheets'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> reviewAdminWorksheet(int id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/admin/daily-worksheets/$id/review'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to review admin worksheet'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAdminTeamApprovals() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/admin/team-approvals'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load team approvals'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static List<dynamic>? _cachedProjects;

  static Future<Map<String, dynamic>> getProjects({List<dynamic>? fallbackData}) async {
    if (_cachedProjects != null && _cachedProjects!.isNotEmpty) {
      return {'error': false, 'data': _cachedProjects};
    }

    // Try multiple speculative endpoints
    final endpoints = ['/projects', '/employee/projects', '/my-assignments', '/employee/assignments'];
    for (var endpoint in endpoints) {
      try {
        final headers = await _headers();
        final response = await http
            .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = _extractList(data);
          if (list.isNotEmpty) {
            _cachedProjects = list;
            return {'error': false, 'data': list};
          }
        }
      } catch (_) {}
    }

    // If all fail, try to extract from provided fallback worksheets
    if (fallbackData != null && fallbackData.isNotEmpty) {
      final Map<dynamic, dynamic> extracted = {};
      for (var item in fallbackData) {
        final p = item['project'];
        final pId = item['project_id'] ?? (p is Map ? p['id'] : null);
        final pName = item['project_name'] ?? (p is Map ? p['name'] : (p is String ? p : null));
        
        if (pId != null && pName != null) {
          extracted[pId] = pName;
        }
      }
      if (extracted.isNotEmpty) {
        final list = extracted.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
        _cachedProjects = list;
        return {'error': false, 'data': list};
      }
    }

    // Absolute fallback
    return {
      'error': false,
      'data': [
        {'id': 1, 'name': 'CRM Development'},
        {'id': 2, 'name': 'Mobile App'},
        {'id': 3, 'name': 'Marketing Campaign'},
        {'id': 4, 'name': 'Infrastructure'},
      ]
    };
  }

  // ─── Official Leaves (Company Holidays) ────────────────────────────────────

  // Admin Official Leaves
  static Future<Map<String, dynamic>> getAdminOfficialLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/admin/official-leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load official leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createAdminOfficialLeave(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/admin/official-leaves'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      
      String? errorMessage;
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          errorMessage = (data['errors'] as Map).values.map((v) => v.toString()).join(", ");
        } else {
          errorMessage = data['errors'].toString();
        }
      }

      return {
        'error': true, 
        'message': errorMessage ?? data['message'] ?? 'Failed to create official leave'
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminOfficialLeave(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      // For Laravel compatibility, sometimes PATCH via POST with _method is safer,
      // but here we'll stick to PATCH and ensure we parse validation errors correctly.
      final response = await http
          .patch(Uri.parse('$baseUrl/admin/official-leaves/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      
      String? errorMessage;
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          errorMessage = (data['errors'] as Map).values.map((v) => v.toString()).join(", ");
        } else {
          errorMessage = data['errors'].toString();
        }
      }
      
      return {
        'error': true, 
        'message': errorMessage ?? data['message'] ?? 'Failed to update official leave'
      };
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Removed duplicate updateAdminOfficialLeave call as it's now integrated above

  static Future<Map<String, dynamic>> deleteAdminOfficialLeave(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/official-leaves/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete official leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Manager Official Leaves
  static Future<Map<String, dynamic>> getManagerOfficialLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/official-leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load official leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createManagerOfficialLeave(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/manager/official-leaves'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};

      String? errorMessage;
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          errorMessage = (data['errors'] as Map).values.map((v) => v.toString()).join(", ");
        } else {
          errorMessage = data['errors'].toString();
        }
      }

      return {'error': true, 'message': errorMessage ?? data['message'] ?? 'Failed to create official leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateManagerOfficialLeave(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .patch(Uri.parse('$baseUrl/manager/official-leaves/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};

      String? errorMessage;
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          errorMessage = (data['errors'] as Map).values.map((v) => v.toString()).join(", ");
        } else {
          errorMessage = data['errors'].toString();
        }
      }

      return {'error': true, 'message': errorMessage ?? data['message'] ?? 'Failed to update official leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteManagerOfficialLeave(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/manager/official-leaves/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete official leave'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Employee Official Leaves
  static Future<Map<String, dynamic>> getEmployeeOfficialLeaves() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/official-leaves'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load official leaves'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'];
      // Handle nested tasks structure: { "data": { "tasks": [...] } }
      if (data['data'] is Map) {
        final nestedData = data['data'] as Map;
        if (nestedData['tasks'] is List) return nestedData['tasks'];
        if (nestedData['data'] is List) return nestedData['data'];
      }
      // Fallback: search all values
      for (var val in data.values) {
        if (val is List) return val;
        if (val is Map) {
          for (var innerVal in val.values) {
            if (innerVal is List) return innerVal;
          }
        }
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteEmployeeDailyWorksheet(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/employee/daily-worksheets/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete worksheet'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteManagerDailyWorksheet(int id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/manager/daily-worksheets/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete worksheet'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Extract a human-readable error message from a Laravel validation response.
  static String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Operation failed';
    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final msgs = <String>[];
      for (final v in errors.values) {
        if (v is List) {
          msgs.addAll(v.map((e) => e.toString()));
        } else {
          msgs.add(v.toString());
        }
      }
      if (msgs.isNotEmpty) return msgs.join('\n');
    }
    return data['message']?.toString() ?? 'Operation failed';
  }

  // ─── Events / Meetings ────────────────────────────────────────────────────

  // --- Admin Events ---
  static Future<Map<String, dynamic>> getAdminEvents() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/admin/events'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load events'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createAdminEvent(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/events'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminEvent(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/events/$id'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdminEvent(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/events/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> markAdminEventViewed(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/admin/events/$id/mark-view'), headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false};
      return {'error': true, 'message': 'Failed to mark event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // --- Manager Events ---
  static Future<Map<String, dynamic>> getManagerEvents() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/manager/events'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load events'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createManagerEvent(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$baseUrl/manager/events'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateManagerEvent(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(
            Uri.parse('$baseUrl/manager/events/$id'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteManagerEvent(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/manager/events/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> markManagerEventViewed(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/manager/events/$id/mark-view'), headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false};
      return {'error': true, 'message': 'Failed to mark event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // --- Employee Events ---
  static Future<Map<String, dynamic>> getEmployeeEvents() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/employee/events'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load events'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createEmployeeEvent(Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(
            Uri.parse('$baseUrl/employee/events'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateEmployeeEvent(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(
            Uri.parse('$baseUrl/employee/events/$id'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteEmployeeEvent(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/employee/events/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> markEmployeeEventViewed(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/employee/events/$id/mark-view'), headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false};
      return {'error': true, 'message': 'Failed to mark event'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ─── Task Management ──────────────────────────────────────────────────────

  // --- Admin Tasks ---
  static Future<Map<String, dynamic>> getAdminTasks() async {
    try {
      final headers = await _headers();
      final url = '$baseUrl/admin/tasks';
      debugPrint('Fetching Admin Tasks from: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load tasks'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createAdminTask(Map<String, dynamic> body, {List<File>? attachments}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/tasks'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          request.files.add(await http.MultipartFile.fromPath('attachments[]', file.path));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminTask(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl/admin/tasks/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdminTask(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/tasks/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete task'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getManagerTasks({Map<String, dynamic>? queryParams}) async {
    try {
      final headers = await _headers();
      var uri = Uri.parse('$baseUrl/manager/tasks');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
      }
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load tasks'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createManagerTask(Map<String, dynamic> body, {List<File>? attachments}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/manager/tasks'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Add text fields
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add attachments
      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          request.files.add(await http.MultipartFile.fromPath('attachments[]', file.path));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateManagerTask(dynamic id, Map<String, dynamic> body) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl/manager/tasks/$id'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteManagerTask(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/manager/tasks/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      return {'error': true, 'message': 'Failed to delete task'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // --- Employee Tasks ---
  static Future<Map<String, dynamic>> getEmployeeTasks() async {
    try {
      final headers = await _headers();
      final url = '$baseUrl/employee/tasks';
      debugPrint('Fetching Employee Tasks from: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load employee tasks'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getEmployeeTasksAssignedByMe() async {
    try {
      final headers = await _headers();
      final url = '$baseUrl/employee/tasks/assigned-by-me';
      debugPrint('Fetching Employee Assigned By Me Tasks from: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': _extractList(data)};
      return {'error': true, 'message': data['message'] ?? 'Failed to load tasks'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateTaskStatus(dynamic id, String status, {String? liveLink}) async {
    try {
      final headers = await _headers();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/employee/tasks/$id/status'),
            headers: headers,
            body: jsonEncode({
              'status': status,
              if (liveLink != null) 'live_link': liveLink,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> startTaskTimer(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/employee/tasks/$id/start-timer'), headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to start timer'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> stopTaskTimer(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/employee/tasks/$id/stop-timer'), headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to stop timer'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ─── Invoices ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInvoices() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/admin/invoices'), headers: headers)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, 'data': data['data'] ?? data};
      return {'error': true, 'message': data['message'] ?? 'Failed to load invoices'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$baseUrl/admin/invoices'), headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) return {'error': false, ...resBody};
      return {'error': true, 'message': resBody['message'] ?? 'Failed to create invoice'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateInvoice(dynamic id, Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl/admin/invoices/$id'), headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...resBody};
      return {'error': true, 'message': resBody['message'] ?? 'Failed to update invoice'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteInvoice(dynamic id) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/invoices/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to delete invoice'};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> downloadInvoicePdf(dynamic id) async {
    // This would typically return a URL or raw bytes
    return {'error': false, 'url': '$baseUrl/admin/invoices/$id/download'};
  }
}
