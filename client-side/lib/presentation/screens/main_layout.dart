import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/layout/responsive.dart';
import 'package:legion/core/theme/app_theme.dart';
import 'package:legion/domain/entities/session.dart';
import 'package:legion/presentation/screens/admin/admin_menu_screen.dart';
import 'package:legion/presentation/screens/admin/runners_admin_screen.dart';
import 'package:legion/presentation/screens/admin/users_admin_screen.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:legion/presentation/screens/auth/bloc/auth_state.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:legion/presentation/screens/chat/bloc/chat_event.dart';
import 'package:legion/presentation/screens/chat/widgets/chat_content.dart';
import 'package:legion/presentation/screens/chat/widgets/sessions_sidebar.dart';
import 'package:legion/presentation/screens/profile/profile_screen.dart';
import 'package:legion/presentation/widgets/app_bottom_nav.dart';
import 'package:legion/presentation/widgets/side_navigation.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  NavDestination _destination = NavDestination.home;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sessionsSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(ChatStarted());
    });
  }

  void _createNewSession() {
    context.read<ChatBloc>().add(const ChatCreateSession());
  }

  void _selectSession(ChatSession session) {
    context.read<ChatBloc>().add(ChatSelectSession(session.id));
  }

  void _selectSessionAndCloseDrawer(ChatSession session) {
    _selectSession(session);
    if (Breakpoints.useDrawerForSessions(context)) {
      Navigator.of(context).pop();
    }
  }

  void _deleteSession(String sessionId, String sessionTitle) {
    final chatBloc = context.read<ChatBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить сессию?'),
        content: Text('Вы уверены, что хотите удалить сессию "$sessionTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              chatBloc.add(ChatDeleteSession(sessionId));
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Удалить', 
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    final useDrawer = Breakpoints.useDrawerForSessions(context);
    final sessionsSidebar = SessionsSidebar(
      isInDrawer: useDrawer,
      onCreateNewSession: _createNewSession,
      onSelectSession: useDrawer 
        ? _selectSessionAndCloseDrawer 
        : _selectSession,
      onDeleteSession: _deleteSession,
    );

    if (useDrawer) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(child: SafeArea(child: sessionsSidebar)),
        body: ChatContent(
          onOpenSessionsDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: _sessionsSidebarVisible ? Breakpoints.sidebarDefaultWidth : 0,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppTheme.channelsBackground(context),
            border: Border(
              right: BorderSide(
                color: _sessionsSidebarVisible
                  ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              ),
            ),
          ),
          child: _sessionsSidebarVisible
              ? sessionsSidebar
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: ChatContent(
            onToggleSessionsSidebar: () => setState(
              () => _sessionsSidebarVisible = !_sessionsSidebarVisible,
            ),
            isSessionsSidebarVisible: _sessionsSidebarVisible,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBody() {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute<void>(
            builder: (context) => AdminMenuScreen(
              onSelectRunners: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RunnersAdminScreen(),
                ),
              ),
              onSelectUsers: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UsersAdminScreen(),
                ),
              ),
            ),
          );
        }
        return null;
      },
    );
  }

  Widget _buildBody() {
    switch (_destination) {
      case NavDestination.home:
        return _buildHomeBody();
      case NavDestination.profile:
        return const ProfileScreen();
      case NavDestination.admin:
        return _buildAdminBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => (prev.user?.isAdmin ?? false) != (curr.user?.isAdmin ?? false),
      builder: (context, authState) {
        final isAdmin = authState.user?.isAdmin ?? false;
        final nav = isMobile ? AppBottomNav(
          selected: _destination,
          onDestinationSelected: (d) => setState(() => _destination = d),
          showAdmin: isAdmin,
        ) : SideNavigation(
          selected: _destination,
          onDestinationSelected: (d) => setState(() => _destination = d),
          showAdmin: isAdmin,
        );
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: isMobile ? Column(
            children: [
              Expanded(child: _buildBody()),
              nav,
            ],
          ): Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nav,
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }
}
