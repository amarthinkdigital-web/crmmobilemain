import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // To access ApiService.baseUrl

class RecruitingApiService {
  static Future<Map<String, String>> _headers({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── 1. Interviews CRUD ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInterviews({
    int page = 1,
    int perPage = 15,
    String? status,
    String? applyFor,
    String? search,
  }) async {
    try {
      final headers = await _headers();
      List<String> queryParams = ['page=$page', 'per_page=$perPage'];
      if (status != null && status.isNotEmpty) queryParams.add('status=$status');
      if (applyFor != null && applyFor.isNotEmpty) queryParams.add('apply_for=$applyFor');
      if (search != null && search.isNotEmpty) queryParams.add('search=$search');

      final url = '${ApiService.baseUrl}/interviews?${queryParams.join('&')}';
      final response = await http.get(Uri.parse(url), headers: headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'error': false, ...data};
      }
      return {'error': true, 'message': data['message'] ?? 'Failed to load interviews'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createInterview(
    Map<String, dynamic> data,
    List<String> filePaths,
  ) async {
    try {
      final headers = await _headers(isMultipart: true);
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/interviews'));
      request.headers.addAll(headers);

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      for (var path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('task_files[]', path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'error': false, ...responseData};
      }
      return {'error': true, 'message': responseData['message'] ?? 'Failed to create interview'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getInterviewDetails(int id) async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/interviews/$id'), headers: headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'error': false, 'data': data['data']};
      }
      return {'error': true, 'message': data['message'] ?? 'Failed to load interview details'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateInterview(
    int id,
    Map<String, dynamic> data,
    List<String> newFilePaths, {
    List<String>? removeFiles,
  }) async {
    try {
      final headers = await _headers(isMultipart: true);
      // Laravel handles PUT with multipart using POST and _method=PUT
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/interviews/$id'));
      request.headers.addAll(headers);
      request.fields['_method'] = 'PUT';

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (removeFiles != null) {
        for (int i = 0; i < removeFiles.length; i++) {
          request.fields['remove_files[$i]'] = removeFiles[i];
        }
      }

      for (var path in newFilePaths) {
        request.files.add(await http.MultipartFile.fromPath('task_files[]', path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'error': false, ...responseData};
      }
      return {'error': true, 'message': responseData['message'] ?? 'Failed to update interview'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteInterview(int id) async {
    try {
      final headers = await _headers();
      final response = await http.delete(Uri.parse('${ApiService.baseUrl}/interviews/$id'), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'error': false};
      }
      final data = jsonDecode(response.body);
      return {'error': true, 'message': data['message'] ?? 'Failed to delete interview'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ─── 2. HR Users ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getHrUsers() async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/interviews/hr-users'), headers: headers);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'data': data['data'] ?? data};
      }
      return {'error': true, 'message': data['message'] ?? 'Failed to load HR users'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ─── 3. Interview Actions ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> confirmInterview(int id) async {
    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse('${ApiService.baseUrl}/interviews/$id/confirm'), headers: headers);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to confirm interview'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> changeStatus(int id, String status, String remarks) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/interviews/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status, 'remarks': remarks}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...data};
      return {'error': true, 'message': data['message'] ?? 'Failed to update status'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ─── 4. Follow Ups ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addFollowUp(int interviewId, Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/interviews/$interviewId/follow-ups'),
        headers: headers,
        body: jsonEncode(data),
      );
      final respData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return {'error': false, ...respData};
      return {'error': true, 'message': respData['message'] ?? 'Failed to add follow up'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateFollowUp(int followUpId, Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/interview-follow-ups/$followUpId'),
        headers: headers,
        body: jsonEncode(data),
      );
      final respData = jsonDecode(response.body);
      if (response.statusCode == 200) return {'error': false, ...respData};
      return {'error': true, 'message': respData['message'] ?? 'Failed to update follow up'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteFollowUp(int followUpId) async {
    try {
      final headers = await _headers();
      final response = await http.delete(Uri.parse('${ApiService.baseUrl}/interview-follow-ups/$followUpId'), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) return {'error': false};
      final respData = jsonDecode(response.body);
      return {'error': true, 'message': respData['message'] ?? 'Failed to delete follow up'};
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  // ─── 5. Email Actions ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _sendMailAction(String urlPath, Map<String, dynamic> body, {String? filePath, String? fileField}) async {
    try {
      if (filePath != null && fileField != null) {
        final headers = await _headers(isMultipart: true);
        var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}$urlPath'));
        request.headers.addAll(headers);
        body.forEach((key, value) {
          if (value != null) request.fields[key] = value.toString();
        });
        request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) return {'error': false, ...data};
        return {'error': true, 'message': data['message'] ?? 'Failed to send mail'};
      } else {
        final headers = await _headers();
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}$urlPath'),
          headers: headers,
          body: jsonEncode(body),
        );
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) return {'error': false, ...data};
        return {'error': true, 'message': data['message'] ?? 'Failed to send mail'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendTaskMail(int id, Map<String, dynamic> body) => _sendMailAction('/interviews/$id/send-task-mail', body);
  static Future<Map<String, dynamic>> sendHoldMail(int id, Map<String, dynamic> body) => _sendMailAction('/interviews/$id/send-hold-mail', body);
  static Future<Map<String, dynamic>> sendRejectionMail(int id, Map<String, dynamic> body) => _sendMailAction('/interviews/$id/send-rejection-mail', body);
  static Future<Map<String, dynamic>> sendOfferMail(int id, Map<String, dynamic> body, {String? filePath}) => _sendMailAction('/interviews/$id/send-offer-mail', body, filePath: filePath, fileField: 'offer_letter');
  static Future<Map<String, dynamic>> sendJoiningMail(int id, Map<String, dynamic> body, {String? filePath}) => _sendMailAction('/interviews/$id/send-joining-mail', body, filePath: filePath, fileField: 'joining_letter');

}
