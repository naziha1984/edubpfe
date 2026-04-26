import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../components/message_bubble.dart';
import '../components/loading.dart';
import '../utils/error_handler.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.title,
  });

  final String conversationId;
  final String receiverId;
  final String title;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _ctrl = TextEditingController();

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
      () => provider.loadMessages(widget.conversationId),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final provider = Provider.of<MessagesProvider>(context, listen: false);
    await ErrorHandler.handleApiCall<void>(
      context,
      () => provider.sendMessage(
        receiverId: widget.receiverId,
        message: text,
        openConversationId: widget.conversationId,
      ),
    );
    if (!mounted) return;
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessagesProvider>(context);
    final myId = Provider.of<AuthProvider>(context).user?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: provider.loadingMessages
                ? const Loading(message: 'Chargement...')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, i) {
                      final m = provider.messages[i];
                      return MessageBubble(
                        text: m.message,
                        isMine: m.senderId == myId,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: provider.sending ? null : _send,
                    icon: provider.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
