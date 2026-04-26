class ConversationModel {
  final String id;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;

  ConversationModel({
    required this.id,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final other = (json['otherUser'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(json['lastMessageAt'].toString()),
      unreadCount: (json['unreadCount'] is num) ? (json['unreadCount'] as num).toInt() : 0,
      otherUserId: other['id']?.toString() ?? '',
      otherUserName: other['fullName']?.toString() ?? '',
      otherUserRole: other['role']?.toString() ?? '',
    );
  }
}
