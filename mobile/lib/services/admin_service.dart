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
}
