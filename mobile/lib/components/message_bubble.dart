import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
  });

  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isMine ? EduBridgeColors.primary.withOpacity(0.16) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EduBridgeColors.surfaceVariant),
        ),
        child: Text(text),
      ),
    );
  }
}
