import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';
import '../components/loading.dart';
import '../components/empty_state.dart';
import '../utils/error_handler.dart';
import 'chat_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final provider = Provider.of<MessagesProvider>(context, listen: false);
    await ErrorHandler.handleApiCall<void>(
      context,
      provider.loadConversations,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessagesProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: provider.loadingConversations
          ? const Loading(message: 'Chargement des conversations...')
          : provider.conversations.isEmpty
              ? const EmptyState(
                  icon: Icons.mail_outline_rounded,
                  title: 'Aucune conversation',
                  message: 'Tes messages directs apparaîtront ici.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: provider.conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = provider.conversations[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        title: Text(c.otherUserName.isEmpty ? 'Conversation' : c.otherUserName),
                        subtitle: Text(
                          c.lastMessage.isEmpty ? 'Aucun message' : c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: c.unreadCount > 0
                            ? CircleAvatar(
                                radius: 11,
                                child: Text(
                                  '${c.unreadCount}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(
                                conversationId: c.id,
                                receiverId: c.otherUserId,
                                title: c.otherUserName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
