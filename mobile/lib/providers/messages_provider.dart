import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/direct_message_model.dart';
import '../services/api_service.dart';

class MessagesProvider with ChangeNotifier {
  final ApiService _apiService;
  MessagesProvider(this._apiService);

  List<ConversationModel> _conversations = [];
  List<DirectMessageModel> _messages = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  bool _sending = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<DirectMessageModel> get messages => _messages;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  bool get sending => _sending;
  String? get error => _error;
  int get totalUnread =>
      _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  Future<void> loadConversations() async {
    _loadingConversations = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _apiService.getConversations();
      _conversations = data
          .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _loadingConversations = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingConversations = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _loadingMessages = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _apiService.getConversationMessages(conversationId);
      _messages = data
          .map((e) => DirectMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _loadingMessages = false;
      notifyListeners();
      await _apiService.markConversationRead(conversationId);
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      _loadingMessages = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String message,
    String? openConversationId,
  }) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.sendDirectMessage(
        receiverId: receiverId,
        message: message,
      );
      final created = DirectMessageModel.fromJson(response);
      if (openConversationId != null &&
          created.conversationId == openConversationId) {
        _messages = [..._messages, created];
      }
      _sending = false;
      notifyListeners();
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      _sending = false;
      notifyListeners();
      rethrow;
    }
  }
}
