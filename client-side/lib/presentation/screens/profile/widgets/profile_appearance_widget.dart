import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/theme/app_theme.dart';
import 'package:skeleton/presentation/theme/theme_cubit.dart';
import 'package:skeleton/presentation/theme/theme_state.dart';

class ProfileAppearanceWidget extends StatelessWidget {
  const ProfileAppearanceWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: BlocBuilder<ThemeCubit, ThemeState>(
            buildWhen: (a, b) => a.themeMode != b.themeMode,
            builder: (context, themeState) {
              final isDark = themeState.themeMode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Тёмная тема'),
                subtitle: Text(isDark ? 'Включена' : 'Выключена'),
                value: isDark,
                onChanged: (value) {
                  context.read<ThemeCubit>().setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Цвет акцента',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<ThemeCubit, ThemeState>(
                  buildWhen: (a, b) => a.accentColorId != b.accentColorId,
                  builder: (context, themeState) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final option in AppTheme.accentColorOptions)
                          _AccentColorChip(
                            option: option,
                            isSelected: themeState.accentColorId == option.id,
                            onTap: () {
                              context.read<ThemeCubit>().setAccentColorId(
                                option.id,
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final content = Padding(padding: const EdgeInsets.all(24), child: column);
    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }
}

class _AccentColorChip extends StatelessWidget {
  final AccentColorOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentColorChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: option.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: option.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
        ),
      ),
    );
  }
}
