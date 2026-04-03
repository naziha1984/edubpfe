import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  String? _token;
  String? _kidToken;

  // Token management
  void setToken(String? token) {
    _token = token;
  }

  void setKidToken(String? token) {
    _kidToken = token;
  }

  String? get token => _token;
  String? get kidToken => _kidToken;

  // Helper method to get headers
  Map<String, String> _getHeaders({bool useKidToken = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (useKidToken && _kidToken != null) {
      headers['Authorization'] = 'Bearer $_kidToken';
    } else if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Handle API response
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
      return {};
    }

    return json.decode(response.body);
  }

  // Auth endpoints
  /// [role] : 'PARENT' ou 'TEACHER' (défaut PARENT)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'PARENT',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: json.encode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toUpperCase(),
      }),
    );

    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      _token = data['access_token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      _token = data['access_token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _getHeaders(),
    );

    return await _handleResponse(response);
  }

  // Kids endpoints
  Future<List<dynamic>> getKids() async {
    final response = await http.get(
      Uri.parse('$baseUrl/kids'),
      headers: _getHeaders(),
    );

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

    final data = json.decode(response.body);
    // API returns array directly
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> addKid({
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? grade,
    String? school,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kids'),
      headers: _getHeaders(),
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (grade != null) 'grade': grade,
        if (school != null) 'school': school,
      }),
    );

    return await _handleResponse(response);
  }

  Future<void> setPin({
    required String kidId,
    required String pin,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/kids/$kidId/pin'),
      headers: _getHeaders(),
      body: json.encode({'pin': pin}),
    );

    await _handleResponse(response);
  }

  /// Inscrit un enfant à une classe avec le code communiqué par l'enseignant.
  /// Réservé au compte PARENT (JWT).
  Future<Map<String, dynamic>> joinClass({
    required String kidId,
    required String classCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes/join'),
      headers: _getHeaders(),
      body: json.encode({
        'kidId': kidId,
        'classCode': classCode.trim().toUpperCase(),
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyPin({
    required String kidId,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kids/$kidId/verify-pin'),
      headers: _getHeaders(),
      body: json.encode({'pin': pin}),
    );

    final data = await _handleResponse(response);
    if (data['kidToken'] != null) {
      _kidToken = data['kidToken'];
    }
    return data;
  }

  // Subjects and Lessons endpoints
  Future<List<dynamic>> getSubjects() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects'),
      headers: _getHeaders(),
    );

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

    final data = json.decode(response.body);
    // API returns array directly
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<List<dynamic>> getLessons(String subjectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects/$subjectId/lessons'),
      headers: _getHeaders(),
    );

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

    final data = json.decode(response.body);
    // API returns array directly
    if (data is List) {
      return data;
    }
    return [];
  }

  // Quiz endpoints
  Future<Map<String, dynamic>> createQuizSession({
    required String kidId,
    required String lessonId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/sessions'),
      headers: _getHeaders(useKidToken: true),
      body: json.encode({
        'kidId': kidId,
        'lessonId': lessonId,
      }),
    );

    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> submitQuiz({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/submit'),
      headers: _getHeaders(useKidToken: true),
      body: json.encode({
        'sessionId': sessionId,
        'answers': answers,
      }),
    );

    return await _handleResponse(response);
  }

  // Chatbot endpoints (kid session required)
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/message'),
      headers: _getHeaders(useKidToken: true),
      body: json.encode({'message': message}),
    );

    return await _handleResponse(response);
  }

  Future<List<dynamic>> getChatbotHistory({
    required String sessionId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/history/$sessionId'),
      headers: _getHeaders(useKidToken: true),
    );

    final data = await _handleResponse(response);
    if (data is List) {
      return data;
    }
    return [];
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
