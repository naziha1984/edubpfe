import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints admin
class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  /// Récupère les headers avec le token admin
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = _apiService.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Gère la réponse de l'API
  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      throw ApiException('Unauthorized', 401);
    }
    if (response.statusCode == 403) {
      throw ApiException('Forbidden - Admin access required', 403);
    }
    if (response.statusCode >= 400) {
      try {
        final error = json.decode(response.body);
        throw ApiException(
          error['message'] ?? error['error'] ?? 'An error occurred',
          response.statusCode,
        );
      } catch (e) {
        throw ApiException(
          'An error occurred',
          response.statusCode,
        );
      }
    }

    if (response.body.isEmpty) {
      return [];
    }

    return json.decode(response.body);
  }

  /// GET /admin/users - Récupère tous les utilisateurs
  /// Query params optionnels: ?role=ADMIN&search=email
  Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    String? search,
  }) async {
    var url = Uri.parse('${ApiService.baseUrl}/admin/users');
    
    // Ajouter les query params
    final queryParams = <String, String>{};
    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);
    
    // Si c'est une liste, la retourner directement
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    
    // Sinon, retourner une liste vide
    return [];
  }

  /// GET /admin/kids - Liste tous les enfants (admin)
  Future<List<Map<String, dynamic>>> getKids() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/kids'),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// GET /admin/stats - Récupère les statistiques (KPIs)
  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/stats'),
      headers: _getHeaders(),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardOverview() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/dashboard/overview'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNotificationsOverview() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/notifications/overview'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTeachers({
    String? status,
    String? search,
  }) async {
    var url = Uri.parse('${ApiService.baseUrl}/admin/teachers');
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final response = await http.get(url, headers: _getHeaders());
    final data = await _handleResponse(response);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPendingTeachers() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/teachers/pending'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> getTeacherDetails(String teacherId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/teachers/$teacherId'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptTeacher(String teacherId) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/admin/teachers/$teacherId/accept'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectTeacher(
    String teacherId, {
    String? rejectionReason,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/admin/teachers/$teacherId/reject'),
      headers: _getHeaders(),
      body: json.encode({
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminLessons({
    String? search,
    String? teacherId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    var url = Uri.parse('${ApiService.baseUrl}/admin/lessons');
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (teacherId != null && teacherId.isNotEmpty) {
      queryParams['teacherId'] = teacherId;
    }
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (dateFrom != null && dateFrom.isNotEmpty) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) queryParams['dateTo'] = dateTo;
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    final response = await http.get(url, headers: _getHeaders());
    final data = await _handleResponse(response);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> moderateLesson(
    String lessonId, {
    required String status,
    String? moderationNote,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/admin/lessons/$lessonId/moderation'),
      headers: _getHeaders(),
      body: json.encode({
        'status': status,
        if (moderationNote != null && moderationNote.trim().isNotEmpty)
          'moderationNote': moderationNote.trim(),
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  String resolveFileUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return '';
    final value = pathOrUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = Uri.parse(ApiService.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    if (value.startsWith('/')) {
      return '$origin$value';
    }
    return '$origin/$value';
  }
}
