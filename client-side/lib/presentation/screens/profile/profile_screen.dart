import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/layout/responsive.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_event.dart';
import 'package:skeleton/presentation/screens/profile/profile_section.dart';
import 'package:skeleton/presentation/screens/profile/profile_section_screen.dart';
import 'package:skeleton/presentation/screens/profile/widgets/profile_appearance_widget.dart';
import 'package:skeleton/presentation/screens/profile/widgets/profile_devices_widget.dart';
import 'package:skeleton/presentation/screens/profile/widgets/profile_overview_widget.dart';
import 'package:skeleton/presentation/screens/profile/widgets/profile_security_widget.dart';
import 'package:skeleton/presentation/screens/profile/widgets/profile_sidebar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileSection _section = ProfileSection.overview;

  Widget _buildContent({bool scrollable = true}) {
    return _buildSectionContent(_section, scrollable: scrollable);
  }

  Widget _buildBodyAsSectionList() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      children: [
        for (final section in ProfileSection.values)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(section.icon, color: theme.colorScheme.primary),
              title: Text(section.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                final authBloc = context.read<AuthBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: authBloc,
                      child: ProfileSectionScreen(section: section),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionContent(
    ProfileSection section, {
    bool scrollable = true,
  }) {
    switch (section) {
      case ProfileSection.overview:
        return ProfileOverviewWidget(scrollable: scrollable);
      case ProfileSection.devices:
        return const ProfileDevicesWidget();
      case ProfileSection.appearance:
        return ProfileAppearanceWidget(scrollable: scrollable);
      case ProfileSection.security:
        return ProfileSecurityWidget(scrollable: scrollable);
    }
  }

  String get _sectionTitle => _section.label;

  void _onSectionSelected(ProfileSection section) {
    setState(() => _section = section);
  }

  void _logout() {
    final authBloc = context.read<AuthBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              authBloc.add(const AuthLogoutRequested());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar =
        Breakpoints.isDesktop(context) || Breakpoints.isTablet(context);

    if (showSidebar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_sectionTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: _logout,
            ),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileSidebar(
              selected: _section,
              onSectionSelected: _onSectionSelected,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBodyAsSectionList(),
    );
  }
}
