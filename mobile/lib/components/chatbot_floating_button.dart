import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../main.dart';

class ChatbotFloatingButton extends StatelessWidget {
  const ChatbotFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final navContext = appNavigatorKey.currentContext;
          if (navContext == null) {
            return;
          }
          showModalBottomSheet<void>(
            context: navContext,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _ChatbotPanel(),
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Chatbot',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotPanel extends StatefulWidget {
  const _ChatbotPanel();

  @override
  State<_ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<_ChatbotPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMsg> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final api = Provider.of<ApiService>(context, listen: false);

    if (api.token == null && api.kidToken == null) {
      setState(() {
        _messages.add(
          _ChatMsg(
            text:
                'Connecte-toi (parent, enseignant ou enfant avec code PIN) pour utiliser le chatbot. '
                "Sur l'écran d'accueil, connecte un compte ou ouvre une session enfant.",
            isUser: false,
          ),
        );
      });
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatMsg(text: text, isUser: true));
    });
    _controller.clear();

    try {
      final data = await api.sendChatbotMessage(message: text);
      final reply = (data['response'] ?? '').toString();
      setState(() {
        _messages.add(
          _ChatMsg(
            text: reply.isEmpty ? 'Pas de réponse du chatbot.' : reply,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMsg(
            text: 'Erreur chatbot: $e',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.smart_toy_rounded),
            title: Text('EduBridge Chatbot'),
            subtitle: Text('Visible en permanence'),
          ),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final loggedIn = auth.isAuthenticated;
                          final hasKid =
                              Provider.of<ApiService>(context, listen: false)
                                  .kidToken !=
                              null;
                          if (loggedIn || hasKid) {
                            return const Text(
                              'Pose une question au chatbot ci-dessous, puis envoie ton message.',
                              textAlign: TextAlign.center,
                            );
                          }
                          return const Text(
                            'Pose une question au chatbot.\n'
                            'Connecte-toi (parent / enseignant) ou ouvre une session enfant (PIN) pour envoyer des messages.',
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return Align(
                        alignment: m.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: m.isUser
                                ? Colors.indigo.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.text),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Écris ton message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
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
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;

  _ChatMsg({required this.text, required this.isUser});
}

