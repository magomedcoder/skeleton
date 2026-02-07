import 'package:flutter/material.dart';

enum ProfileSection { overview, devices, appearance, security }

extension ProfileSectionX on ProfileSection {
  String get label {
    switch (this) {
      case ProfileSection.overview:
        return 'Профиль';
      case ProfileSection.devices:
        return 'Устройства';
      case ProfileSection.appearance:
        return 'Оформление';
      case ProfileSection.security:
        return 'Безопасность';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileSection.overview:
        return Icons.person_outline_rounded;
      case ProfileSection.devices:
        return Icons.devices_rounded;
      case ProfileSection.appearance:
        return Icons.palette_outlined;
      case ProfileSection.security:
        return Icons.lock_outline_rounded;
    }
  }
}
