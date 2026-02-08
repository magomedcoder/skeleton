import 'package:flutter/material.dart';
import 'package:legion/presentation/screens/profile/profile_section.dart';
import 'package:legion/presentation/screens/profile/widgets/profile_appearance_widget.dart';
import 'package:legion/presentation/screens/profile/widgets/profile_devices_widget.dart';
import 'package:legion/presentation/screens/profile/widgets/profile_overview_widget.dart';
import 'package:legion/presentation/screens/profile/widgets/profile_security_widget.dart';

class ProfileSectionScreen extends StatelessWidget {
  const ProfileSectionScreen({super.key, required this.section});

  final ProfileSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.label)),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (section) {
      case ProfileSection.overview:
        return const ProfileOverviewWidget();
      case ProfileSection.devices:
        return const ProfileDevicesWidget();
      case ProfileSection.appearance:
        return const ProfileAppearanceWidget();
      case ProfileSection.security:
        return const ProfileSecurityWidget();
    }
  }
}
