import 'package:flutter/material.dart';

class ChatListAvatar extends StatelessWidget {
  final String title;
  final bool isOnline;
  final double size;

  const ChatListAvatar({
    super.key,
    required this.title,
    required this.isOnline,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.primaryContainer,
          child: Text(
            letter,
            style: TextStyle(
              color: theme.onPrimaryContainer,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                ? theme.primary
                : theme.outline.withValues(alpha: 0.5),
              border: Border.all(color: theme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
