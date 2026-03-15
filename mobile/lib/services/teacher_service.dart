import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints teacher
class TeacherService {
  final ApiService _apiService;

  TeacherService(this._apiService);

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
      throw ApiException('Forbidden - Teacher access required', 403);
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

  /// POST /teacher/classes - Crée une nouvelle classe
  Future<Map<String, dynamic>> createClass(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/teacher/classes'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// GET /teacher/classes - Récupère toutes les classes du teacher
  Future<List<Map<String, dynamic>>> getClasses() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/teacher/classes'),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);
    
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    
    return [];
  }

  /// GET /teacher/classes/:classId - Récupère les détails d'une classe
  Future<Map<String, dynamic>> getClassDetails(String classId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/teacher/classes/$classId'),
      headers: _getHeaders(),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// POST /teacher/classes/:classId/students - Ajoute un élève à une classe
  Future<Map<String, dynamic>> addStudentToClass(
    String classId,
    String kidId,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/teacher/classes/$classId/students'),
      headers: _getHeaders(),
      body: json.encode({'kidId': kidId}),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// DELETE /teacher/classes/:classId/students/:kidId - Supprime un élève d'une classe
  Future<void> removeStudentFromClass(String classId, String kidId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/teacher/classes/$classId/students/$kidId'),
      headers: _getHeaders(),
    );

    await _handleResponse(response);
  }

  /// GET /teacher/classes/:classId/subjects/:subjectId/progress - Récupère le suivi de progression
  Future<Map<String, dynamic>> getClassSubjectProgress(
    String classId,
    String subjectId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/teacher/classes/$classId/subjects/$subjectId/progress',
      ),
      headers: _getHeaders(),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }
}
