import 'package:flutter/material.dart';
import 'package:skeleton/presentation/screens/profile/profile_section.dart';

class ProfileSidebar extends StatelessWidget {
  final ProfileSection selected;
  final ValueChanged<ProfileSection> onSectionSelected;
  final bool expandWidth;

  const ProfileSidebar({
    super.key,
    required this.selected,
    required this.onSectionSelected,
    this.expandWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expandWidth ? null : 240,
      constraints: expandWidth ? null : const BoxConstraints(minWidth: 240),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final section in ProfileSection.values)
            _SidebarTile(
              section: section,
              isSelected: selected == section,
              onTap: () => onSectionSelected(section),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final ProfileSection section;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 22,
                  color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                      color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
