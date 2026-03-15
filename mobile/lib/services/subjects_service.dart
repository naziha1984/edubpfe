import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints subjects (admin CRUD)
class SubjectsService {
  final ApiService _apiService;

  SubjectsService(this._apiService);

  /// Récupère les headers avec le token
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
      return null;
    }

    return json.decode(response.body);
  }

  /// GET /subjects - Récupère tous les subjects (public ou admin)
  Future<List<Map<String, dynamic>>> getSubjects({bool adminOnly = false}) async {
    final url = adminOnly
        ? '${ApiService.baseUrl}/subjects/admin'
        : '${ApiService.baseUrl}/subjects';

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);
    
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    
    return [];
  }

  /// GET /subjects/admin/:id - Récupère un subject par ID (admin)
  Future<Map<String, dynamic>> getSubjectById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/subjects/admin/$id'),
      headers: _getHeaders(),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// POST /subjects - Crée un nouveau subject (admin)
  Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/subjects'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// PUT /subjects/:id - Met à jour un subject (admin)
  Future<Map<String, dynamic>> updateSubject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/subjects/$id'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// DELETE /subjects/:id - Supprime un subject (admin)
  Future<void> deleteSubject(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/subjects/$id'),
      headers: _getHeaders(),
    );

    await _handleResponse(response);
  }
}
