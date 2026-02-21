import 'package:flutter/material.dart';
import 'package:legion/core/date_formatter.dart';
import 'package:legion/domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromMe;
  final VoidCallback? onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
  });

  static const double _bubbleRadius = 18;
  static const double _tailRadius = 4;
  static const double _maxWidthFraction = 0.75;

  static void _showContextMenu(
    BuildContext context,
    Offset? globalPosition,
    VoidCallback? onDelete,
    VoidCallback? onToggleSelection,
  ) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || (!box.hasSize)) {
      return;
    }

    final position = globalPosition ?? box.localToGlobal(box.size.bottomCenter(Offset.zero));
    final menuRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    );

    final items = <PopupMenuEntry<String>>[];
    if (onDelete != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 8),
              Text('Удалить'),
            ],
          ),
        ),
      );
    }
    if (onToggleSelection != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'select',
          child: Row(
            children: [
              Icon(Icons.check_box_outlined, size: 20),
              SizedBox(width: 8),
              Text('Выделить'),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: menuRect,
      items: items,
    ).then((value) {
      if (value == 'delete') {
        onDelete?.call();
      }

      if (value == 'select') {
        onToggleSelection?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(message.createdAt);
    final isDark = theme.brightness == Brightness.dark;

    final sentBubbleColor = isDark
      ? const Color(0xFF2AABEE)
      : theme.colorScheme.primary;
    final receivedBubbleColor = isDark
      ? theme.colorScheme.surfaceContainerHigh
      : theme.colorScheme.surfaceContainerHighest;
    final sentTextColor = theme.colorScheme.onPrimary;
    final receivedTextColor = theme.colorScheme.onSurface;
    final timeColor = isFromMe
      ? sentTextColor.withValues(alpha: 0.85)
      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9);

    final bubbleColor = isFromMe ? sentBubbleColor : receivedBubbleColor;
    final textColor = isFromMe ? sentTextColor : receivedTextColor;

    final showCheckbox = isSelectionMode && isFromMe;
    final onBubbleTap = showCheckbox && onToggleSelection != null
      ? onToggleSelection
      : null;
    final showContextMenu = isFromMe && !isSelectionMode
      && (onDelete != null || onToggleSelection != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * _maxWidthFraction;
        Widget row = Row(
          mainAxisAlignment: isFromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showCheckbox)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onToggleSelection != null
                    ? (_) => onToggleSelection!()
                    : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            Flexible(
              child: GestureDetector(
                onTap: onBubbleTap,
                onLongPress: showContextMenu
                  ? () => _showContextMenu(
                    context,
                    null,
                    onDelete, onToggleSelection,
                  )
                  : (isFromMe && onToggleSelection != null ? onToggleSelection : null),
                onSecondaryTapDown: showContextMenu
                  ? (details) => _showContextMenu(
                    context,
                    details.globalPosition,
                    onDelete,
                    onToggleSelection,
                  )
                  : null,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(_bubbleRadius),
                      topRight: const Radius.circular(_bubbleRadius),
                      bottomLeft: Radius.circular(
                        isFromMe ? _bubbleRadius : _tailRadius,
                      ),
                      bottomRight: Radius.circular(
                        isFromMe ? _tailRadius : _bubbleRadius,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              message.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                height: 1.35,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: timeColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (isFromMe) ...[
                        const SizedBox(height: 2),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: timeColor.withValues(alpha: 0.95),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          child: row,
        );
      },
    );
  }
}
