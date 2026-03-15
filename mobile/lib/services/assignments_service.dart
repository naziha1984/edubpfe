import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints assignments (teacher et kid)
class AssignmentsService {
  final ApiService _apiService;

  AssignmentsService(this._apiService);

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

  /// POST /teacher/assignments - Crée un nouveau devoir
  Future<Map<String, dynamic>> createAssignment(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/teacher/assignments'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// GET /teacher/assignments/class/:classId - Récupère les devoirs d'une classe
  Future<List<Map<String, dynamic>>> getAssignmentsByClass(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/teacher/assignments/class/$classId'),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  /// GET /teacher/assignments/:assignmentId/submissions - Récupère les soumissions d'un devoir
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/teacher/assignments/$assignmentId/submissions',
      ),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  // ========== KID ENDPOINTS ==========

  /// GET /kids/assignments - Récupère tous les devoirs d'un kid
  Future<List<Map<String, dynamic>>> getKidAssignments() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/kids/assignments'),
      headers: _getHeaders(useKidToken: true),
    );

    final data = await _handleResponse(response);

    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  /// POST /kids/assignments/:assignmentId/start - Démarre un devoir
  Future<Map<String, dynamic>> startAssignment(String assignmentId) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/kids/assignments/$assignmentId/start',
      ),
      headers: _getHeaders(useKidToken: true),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// POST /kids/assignments/:assignmentId/submit - Soumet un devoir
  Future<Map<String, dynamic>> submitAssignment(
    String assignmentId, {
    String? quizSessionId,
    double? score,
  }) async {
    final body = <String, dynamic>{};
    if (quizSessionId != null) {
      body['quizSessionId'] = quizSessionId;
    }
    if (score != null) {
      body['score'] = score;
    }

    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/kids/assignments/$assignmentId/submit',
      ),
      headers: _getHeaders(useKidToken: true),
      body: json.encode(body),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }
}
