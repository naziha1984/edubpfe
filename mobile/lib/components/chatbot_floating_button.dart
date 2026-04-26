import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../ui/theme/edubridge_colors.dart';
import '../main.dart';

class ChatbotFloatingButton extends StatefulWidget {
  const ChatbotFloatingButton({super.key});

  @override
  State<ChatbotFloatingButton> createState() => _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState extends State<ChatbotFloatingButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _bounce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _bounce = true);
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (mounted) setState(() => _bounce = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final elevated = _hovered || _pressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : _bounce ? 1.06 : elevated ? 1.03 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [EduBridgeColors.primary, EduBridgeColors.secondary],
            ),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: EduBridgeColors.primary.withOpacity(0.32),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: EduBridgeColors.primary.withOpacity(0.24),
                      blurRadius: 22,
                      spreadRadius: -4,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
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
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
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

