import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'download_helper_mobile.dart' if (dart.library.html) 'download_helper_web.dart' as dh;

class ApiService {
  // Base URL for API calls - Railway Production Backend
  static String baseUrl = 'https://reporting-backend-production.up.railway.app/api';
  static String? _token;

  // Method to set a different base URL (e.g., for mobile testing)
  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  // Save token to local storage
  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get token from local storage
  static Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Clear token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Signup
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Signup failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveToken(data['data']['token']);
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Invalid credentials'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get dashboard stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get stats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get reports
  static Future<Map<String, dynamic>> getReports() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reports'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get reports'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Create report
  static Future<Map<String, dynamic>> createReport({
    required String projectName,
    String? projectCode,
    required String description,
    List<String>? attachments,
    List<String>? voiceNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: headers,
        body: jsonEncode({
          'project_name': projectName,
          'project_code': projectCode,
          'description': description,
          'attachments': attachments ?? [],
          'voice_notes': voiceNotes ?? [],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to create report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update report
  static Future<Map<String, dynamic>> updateReport({
    required String reportId,
    String? projectName,
    String? projectCode,
    String? description,
    String? status,
    String? adminFeedback,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (projectName != null) body['project_name'] = projectName;
      if (projectCode != null) body['project_code'] = projectCode;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;
      if (adminFeedback != null) body['admin_feedback'] = adminFeedback;

      final response = await http.put(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to update report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Delete report
  static Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to delete report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get tasks
  static Future<Map<String, dynamic>> getTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get tasks'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Create task (admin only)
  static Future<Map<String, dynamic>> createTask({
    required String userId,
    required String title,
    String description = '',
    DateTime? dueDate,
    List<String>? attachments,
    List<String>? voiceNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'description': description,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
          'attachments': attachments ?? [],
          'voice_notes': voiceNotes ?? [],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to create task'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update task
  static Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? status,
    List<String>? attachments,
    List<String>? voiceNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;
      if (attachments != null) body['attachments'] = attachments;
      if (voiceNotes != null) body['voice_notes'] = voiceNotes;

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to update task'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get all users (admin only)
  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (department != null) body['department'] = department;
      if (location != null) body['location'] = location;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to update user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get analytics
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/analytics'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Failed to get analytics'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }

  // ========== FILE UPLOAD ==========

  // Upload file bytes to Cloudinary via backend (for Web)
  static Future<String?> uploadFileBytes(String fileName, Uint8List bytes) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Upload bytes error: $e');
      return null;
    }
  }

  // Upload file to Cloudinary via backend
  static Future<String?> uploadFile(String filePath) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ========== LEAVE MANAGEMENT ==========

  // Create leave request
  static Future<Map<String, dynamic>> createLeave(Map<String, dynamic> leaveData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/leaves'),
        headers: headers,
        body: jsonEncode(leaveData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Failed to create leave');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get my leaves
  static Future<List<dynamic>> getMyLeaves() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/leaves/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['leaves'] != null) {
          return data['data']['leaves'] as List<dynamic>;
        }
        return [];
      } else {
        print('Get my leaves error: ${response.statusCode} - ${response.body}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print('Network error getting leaves: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Get all leaves (admin only)
  static Future<List<dynamic>> getAllLeaves({String? status, String? month}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/leaves';
      final queryParams = <String>[];
      if (status != null) queryParams.add('status=$status');
      if (month != null) queryParams.add('month=$month');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['leaves'] != null) {
          return data['data']['leaves'] as List<dynamic>;
        }
        return [];
      } else {
        throw Exception('Failed to load leaves');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update leave status (admin only)
  static Future<void> updateLeaveStatus(String leaveId, String status, String? comment) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'status': status,
        if (comment != null && comment.isNotEmpty) 'admin_comment': comment,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/leaves/$leaveId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Failed to update leave');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get leave statistics (admin only)
  static Future<Map<String, dynamic>> getLeaveStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/leaves/stats/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load leave stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ========== PASSWORD RESET ==========

  // Forgot password - send reset email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Verify reset token
  static Future<Map<String, dynamic>> verifyResetToken(String email, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'token': token}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to verify token');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Reset password with token
  static Future<Map<String, dynamic>> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'reset_token': token,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  // ========== EXPORT DATA (CSV) ==========
  
  static String getExportUrl(String type, {String format = 'csv'}) {
    return '$baseUrl/export/$type?format=$format';
  }

  // Download file (cross-platform helper)
  static Future<void> downloadFile(String url, String fileName) async {
    try {
      final token = await _getToken();
      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        await dh.DownloadHelper.download(bytes, fileName);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      rethrow;
    }
  }
}
