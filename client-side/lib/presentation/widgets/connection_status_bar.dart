import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/connection_status.dart';

class ConnectionStatusBar extends StatefulWidget {
  final bool showInScaffold;

  const ConnectionStatusBar({
    super.key,
    this.showInScaffold = false,
  });

  @override
  State<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends State<ConnectionStatusBar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: context.read<ConnectionStatusService>().statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.connected;

        if (status == ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        return _buildStatusBar(context, status);
      },
    );
  }

  Widget _buildStatusBar(BuildContext context, ConnectionStatus status) {
    final colors = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String text;

    switch (status) {
      case ConnectionStatus.connecting:
        backgroundColor = colors.primaryContainer;
        foregroundColor = colors.onPrimaryContainer;
        icon = Icons.sync;
        text = "Подключение...";
        break;
      case ConnectionStatus.syncing:
        backgroundColor = colors.primaryContainer;
        foregroundColor = colors.onPrimaryContainer;
        icon = Icons.sync;
        text = "Синхронизация...";
        break;
      case ConnectionStatus.waitingForNetwork:
        backgroundColor = colors.errorContainer;
        foregroundColor = colors.onErrorContainer;
        icon = Icons.signal_wifi_off;
        text = "Ожидание сети...";
        break;
      case ConnectionStatus.disconnected:
        backgroundColor = colors.errorContainer;
        foregroundColor = colors.onErrorContainer;
        icon = Icons.cloud_off;
        text = "Нет соединения";
        break;
      default:
        return const SizedBox.shrink();
    }

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
            ),
          ),
          if (status == ConnectionStatus.connecting || status == ConnectionStatus.syncing)
            const SizedBox(width: 10),
          if (status == ConnectionStatus.connecting || status == ConnectionStatus.syncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(foregroundColor),
              ),
            ),
        ],
      ),
    );

    if (widget.showInScaffold) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: content,
        ),
      );
    }

    return content;
  }
}
