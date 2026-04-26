import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
class ApiService {
  /// Par défaut : `http://localhost:3000/api`. Si le backend écoute sur
  /// un autre port, lancez :
  /// `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3001/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  String? _token;
  String? _kidToken;

  // Gestion des jetons
  void setToken(String? token) {
    _token = token;
  }

  void setKidToken(String? token) {
    _kidToken = token;
  }

  String? get token => _token;
  String? get kidToken => _kidToken;

  // Méthode utilitaire pour construire les en-têtes
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

  // Gère la réponse de l'API
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

  Future<dynamic> _handleStreamedResponse(http.StreamedResponse response) async {
    final body = await response.stream.bytesToString();
    final wrapped = http.Response(body, response.statusCode, headers: response.headers);
    return _handleResponse(wrapped);
  }

  // Endpoints d'authentification
  /// [role] : 'PARENT' ou 'TEACHER' (défaut PARENT)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'PARENT',
    Uint8List? cvBytes,
    String? cvFileName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/register'),
    );
    request.fields['email'] = normalizedEmail;
    request.fields['password'] = password;
    request.fields['firstName'] = firstName;
    request.fields['lastName'] = lastName;
    request.fields['role'] = role.toUpperCase();

    if (cvBytes != null && cvFileName != null && cvFileName.trim().isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'cv',
          cvBytes,
          filename: cvFileName,
        ),
      );
    }

    final streamed = await request.send();
    final data = await _handleStreamedResponse(streamed);
    if (data['access_token'] != null) {
      _token = data['access_token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> updateTeacherCv({
    required Uint8List cvBytes,
    required String cvFileName,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/auth/teacher/cv'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'cv',
        cvBytes,
        filename: cvFileName,
      ),
    );
    final streamed = await request.send();
    return await _handleStreamedResponse(streamed) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({
        'email': normalizedEmail,
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

  // Endpoints des enfants
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
    // L'API renvoie directement un tableau
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> addKid({
    required String firstName,
    required String lastName,
    required int schoolLevel,
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
        'schoolLevel': schoolLevel,
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

  Future<List<dynamic>> getAcceptedTeachers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/kids/teachers/accepted'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> getTeacherPublicDetails(String teacherId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/kids/teachers/$teacherId/public'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> selectTeacherForKid({
    required String kidId,
    required String teacherId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/kids/$kidId/teacher/$teacherId'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // Endpoints des matières et leçons
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
    // L'API renvoie directement un tableau
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<List<dynamic>> getLessons(
    String subjectId, {
    int? schoolLevel,
  }) async {
    final query = (schoolLevel != null) ? '?schoolLevel=$schoolLevel' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/subjects/$subjectId/lessons$query'),
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
    // L'API renvoie directement un tableau
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> upsertLessonReview({
    required String lessonId,
    required int stars,
    String? comment,
    String? kidId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/lessons/$lessonId/review'),
      headers: _getHeaders(),
      body: json.encode({
        'stars': stars,
        if (comment != null) 'comment': comment,
        if (kidId != null && kidId.isNotEmpty) 'kidId': kidId,
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLessonReviews(
    String lessonId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lessons/$lessonId/reviews?page=$page&limit=$limit'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherLessonRatingsSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lessons/teacher/ratings-summary'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> getConversationMessages(String conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/messages'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> sendDirectMessage({
    required String receiverId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/direct/$receiverId'),
      headers: _getHeaders(),
      body: json.encode({'message': message}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> markConversationRead(String conversationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/read'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> addStudentNote({
    required String kidId,
    String? behavior,
    String? participation,
    String? homeworkQuality,
    String? comprehension,
    String? recommendations,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student-tracking/students/$kidId/notes'),
      headers: _getHeaders(),
      body: json.encode({
        if (behavior != null && behavior.trim().isNotEmpty) 'behavior': behavior,
        if (participation != null && participation.trim().isNotEmpty)
          'participation': participation,
        if (homeworkQuality != null && homeworkQuality.trim().isNotEmpty)
          'homeworkQuality': homeworkQuality,
        if (comprehension != null && comprehension.trim().isNotEmpty)
          'comprehension': comprehension,
        if (recommendations != null && recommendations.trim().isNotEmpty)
          'recommendations': recommendations,
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addStudentProgressEntry({
    required String kidId,
    required int progressPercent,
    int? comprehensionScore,
    int? homeworkScore,
    int? participationScore,
    String? title,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student-tracking/students/$kidId/progress'),
      headers: _getHeaders(),
      body: json.encode({
        'progressPercent': progressPercent,
        if (comprehensionScore != null) 'comprehensionScore': comprehensionScore,
        if (homeworkScore != null) 'homeworkScore': homeworkScore,
        if (participationScore != null) 'participationScore': participationScore,
        if (title != null && title.trim().isNotEmpty) 'title': title,
        if (note != null && note.trim().isNotEmpty) 'note': note,
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getStudentNotes(String kidId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student-tracking/students/$kidId/notes'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> getStudentProgressHistory(String kidId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student-tracking/students/$kidId/progress'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> getStudentTrackingOverview(String kidId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student-tracking/students/$kidId/overview'),
      headers: _getHeaders(),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // Endpoints des quiz
  Future<Map<String, dynamic>> createQuizSession({
    required String kidId,
    required String lessonId,
    String? difficulty,
  }) async {
    final body = <String, dynamic>{
      'kidId': kidId,
      'lessonId': lessonId,
    };
    if (difficulty != null && difficulty.isNotEmpty) {
      body['difficulty'] = difficulty;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/quiz/sessions'),
      headers: _getHeaders(useKidToken: true),
      body: json.encode(body),
    );

    return await _handleResponse(response);
  }

  /// Aligné sur la session (filtre difficulté créé côté serveur).
  Future<List<dynamic>> getQuizQuestionsForSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quiz/sessions/$sessionId/questions'),
      headers: _getHeaders(useKidToken: true),
    );
    final data = await _handleResponse(response);
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<List<dynamic>> getQuizQuestionsForLesson(
    String lessonId, {
    String? difficulty,
  }) async {
    final q = difficulty != null && difficulty.isNotEmpty
        ? '?difficulty=${Uri.encodeQueryComponent(difficulty)}'
        : '';
    final response = await http.get(
      Uri.parse('$baseUrl/quiz/lessons/$lessonId/questions$q'),
      headers: _getHeaders(useKidToken: true),
    );
    final data = await _handleResponse(response);
    if (data is List) {
      return data;
    }
    return [];
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

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<int> getUnreadNotificationsCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markNotificationRead(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<List<dynamic>> getKidNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/kid'),
      headers: _getHeaders(useKidToken: true),
    );
    final data = await _handleResponse(response);
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<int> getKidUnreadNotificationsCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/kid/unread-count'),
      headers: _getHeaders(useKidToken: true),
    );
    final data = await _handleResponse(response);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markKidNotificationRead(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/kid/$id/read'),
      headers: _getHeaders(useKidToken: true),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getKidRewards() async {
    final response = await http.get(
      Uri.parse('$baseUrl/kid/rewards'),
      headers: _getHeaders(useKidToken: true),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // Endpoints du chatbot (session enfant requise)
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
  }) async {
    final canUseKid = _kidToken != null;
    final endpoint = canUseKid ? '/chatbot/message' : '/chatbot/message-user';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(useKidToken: canUseKid),
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
