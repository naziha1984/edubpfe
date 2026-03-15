import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints live sessions (teacher et kid)
class LiveSessionsService {
  final ApiService _apiService;

  LiveSessionsService(this._apiService);

  /// Récupère les headers avec le token
  Map<String, String> _getHeaders({bool useKidToken = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (useKidToken) {
      final kidToken = _apiService.kidToken;
      if (kidToken != null) {
        headers['Authorization'] = 'Bearer $kidToken';
      }
    } else {
      final token = _apiService.token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Gère la réponse de l'API
  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      throw ApiException('Unauthorized', 401);
    }
    if (response.statusCode == 403) {
      throw ApiException('Forbidden', 403);
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

  // ========== TEACHER ENDPOINTS ==========

  /// POST /teacher/classes/:classId/live-sessions - Crée une nouvelle session live
  Future<Map<String, dynamic>> createLiveSession(
    String classId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/teacher/classes/$classId/live-sessions'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// GET /teacher/classes/:classId/live-sessions - Récupère les sessions live d'une classe
  Future<List<Map<String, dynamic>>> getLiveSessionsByClass(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/teacher/classes/$classId/live-sessions'),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  // ========== KID ENDPOINTS ==========

  /// GET /kid/live-sessions - Récupère toutes les sessions live d'un kid
  Future<List<Map<String, dynamic>>> getKidLiveSessions() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/kid/live-sessions'),
      headers: _getHeaders(useKidToken: true),
    );

    final data = await _handleResponse(response);

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }
}
