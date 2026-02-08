import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/layout/responsive.dart';

void main() {
  group('Breakpoints', () {
    test('константы заданы', () {
      expect(Breakpoints.mobile, 600);
      expect(Breakpoints.tablet, 900);
      expect(Breakpoints.sidebarDefaultWidth, 300);
    });

    testWidgets('isMobile true при ширине < 600', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(Breakpoints.isMobile(context), true);
                expect(Breakpoints.useDrawerForSessions(context), true);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isDesktop при ширине >= 900', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 800)),
            child: Builder(
              builder: (context) {
                expect(Breakpoints.isDesktop(context), true);
                expect(Breakpoints.useDrawerForSessions(context), false);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
