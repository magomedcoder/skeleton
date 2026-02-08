import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legion/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('primaryFromId(0) возвращает первый цвет', () {
      final c = AppTheme.primaryFromId(0);
      expect(c, AppTheme.accentColorOptions[0].color);
    });

    test('primaryFromId с неверным id возвращает цвет по умолчанию', () {
      final c = AppTheme.primaryFromId(-1);
      expect(
        c,
        AppTheme.accentColorOptions[AppTheme.defaultAccentColorId].color,
      );
      final c2 = AppTheme.primaryFromId(100);
      expect(
        c2,
        AppTheme.accentColorOptions[AppTheme.defaultAccentColorId].color,
      );
    });

    test('themeLight создаёт светлую тему', () {
      final theme = AppTheme.themeLight();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);
    });

    test('themeDark создаёт тёмную тему', () {
      final theme = AppTheme.themeDark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);
    });
  });
}
