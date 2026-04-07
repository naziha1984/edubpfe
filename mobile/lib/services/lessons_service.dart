import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service pour les endpoints lessons (admin CRUD)
class LessonsService {
  final ApiService _apiService;

  LessonsService(this._apiService);

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

  Future<Map<String, dynamic>> _handleMultipartResponse(
    http.StreamedResponse streamed,
  ) async {
    final response = await http.Response.fromStream(streamed);
    return await _handleResponse(response) as Map<String, dynamic>;
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

  /// GET /subjects/:id/lessons - Récupère les lessons d'un subject
  Future<List<Map<String, dynamic>>> getLessonsBySubject(String subjectId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/subjects/$subjectId/lessons'),
      headers: _getHeaders(),
    );

    final data = await _handleResponse(response);
    
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    
    return [];
  }

  /// GET /lessons/:id - Récupère une lesson par ID (admin)
  Future<Map<String, dynamic>> getLessonById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/lessons/$id'),
      headers: _getHeaders(),
    );

    return await _handleResponse(response) as Map<String, dynamic>;
  }

  /// POST /lessons - Crée une nouvelle lesson (admin)
  Future<Map<String, dynamic>> createLesson(
    Map<String, dynamic> data,
    List<PlatformFile> files,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/lessons');
    final request = http.MultipartRequest('POST', uri);
    final token = _apiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['subjectId'] = data['subjectId'].toString();
    request.fields['title'] = data['title'].toString();
    if (data['description'] != null) {
      request.fields['description'] = data['description'].toString();
    }
    if (data['content'] != null) {
      request.fields['content'] = data['content'].toString();
    }
    if (data['order'] != null) {
      request.fields['order'] = data['order'].toString();
    }
    if (data['level'] != null) {
      request.fields['level'] = data['level'].toString();
    }
    if (data['language'] != null) {
      request.fields['language'] = data['language'].toString();
    }
    request.fields['isActive'] = (data['isActive'] ?? true).toString();

    for (final f in files) {
      if (f.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            f.bytes!,
            filename: f.name.isNotEmpty ? f.name : 'fichier',
          ),
        );
      } else if (f.path != null && f.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path!,
            filename: f.name.isNotEmpty ? f.name : f.path!.split('/').last,
          ),
        );
      }
    }

    return _handleMultipartResponse(await request.send());
  }

  /// PUT /lessons/:id - Met à jour une lesson (admin)
  Future<Map<String, dynamic>> updateLesson(
    String id,
    Map<String, dynamic> data,
    List<PlatformFile> files,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/lessons/$id');
    final request = http.MultipartRequest('PUT', uri);
    final token = _apiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    for (final entry in data.entries) {
      if (entry.value != null) {
        request.fields[entry.key] = entry.value.toString();
      }
    }
    for (final f in files) {
      if (f.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            f.bytes!,
            filename: f.name.isNotEmpty ? f.name : 'fichier',
          ),
        );
      } else if (f.path != null && f.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f.path!,
            filename: f.name.isNotEmpty ? f.name : f.path!.split('/').last,
          ),
        );
      }
    }

    return _handleMultipartResponse(await request.send());
  }

  /// DELETE /lessons/:id - Supprime une lesson (admin)
  Future<void> deleteLesson(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/lessons/$id'),
      headers: _getHeaders(),
    );

    await _handleResponse(response);
  }
}
