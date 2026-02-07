import 'package:flutter/material.dart';
import 'package:skeleton/core/theme/app_theme.dart';

enum NavDestination { home, editor, profile, admin }

class SideNavigation extends StatelessWidget {
  final NavDestination selected;
  final ValueChanged<NavDestination> onDestinationSelected;
  final bool showAdmin;
  final Widget? trailing;

  const SideNavigation({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
    this.showAdmin = false,
    this.trailing,
  });

  static const double width = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.railBackground(context),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _RailIcon(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            isSelected: selected == NavDestination.home,
            tooltip: 'AI Чаты',
            onTap: () => onDestinationSelected(NavDestination.home),
          ),
          const SizedBox(height: 4),
          _RailIcon(
            icon: Icons.edit_note_outlined,
            selectedIcon: Icons.edit_note_rounded,
            isSelected: selected == NavDestination.editor,
            tooltip: 'Редактор',
            onTap: () => onDestinationSelected(NavDestination.editor),
          ),
          if (showAdmin) ...[
            const SizedBox(height: 4),
            _RailIcon(
              icon: Icons.admin_panel_settings_outlined,
              selectedIcon: Icons.admin_panel_settings_rounded,
              isSelected: selected == NavDestination.admin,
              tooltip: 'Администрирование',
              onTap: () => onDestinationSelected(NavDestination.admin),
            ),
          ],
          const Spacer(),
          _RailIcon(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            isSelected: selected == NavDestination.profile,
            tooltip: 'Профиль',
            onTap: () => onDestinationSelected(NavDestination.profile),
          ),
          const SizedBox(height: 12),
          if (trailing != null) ...[
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            trailing!,
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RailIcon extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final String tooltip;
  final VoidCallback onTap;

  const _RailIcon({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RailIcon> createState() => _RailIconState();
}

class _RailIconState extends State<_RailIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 48,
            width: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isSelected || _hover)
                  Positioned(
                    left: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 4,
                      height: widget.isSelected ? 24 : 12,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (widget.isSelected || _hover)
                      ? theme.colorScheme.primary.withValues(
                          alpha: theme.brightness == Brightness.dark
                            ? 0.2
                            : 0.12,
                        )
                      : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isSelected ? widget.selectedIcon : widget.icon,
                    size: 26,
                    color: color,
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
