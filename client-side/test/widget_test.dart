import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('простой виджет отображает текст', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Skeleton'))),
      ),
    );
    expect(find.text('Skeleton'), findsOneWidget);
  });
}
