import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/app_version.dart';

void main() {
  test('appBuildNumber задан', () {
    expect(appBuildNumber, greaterThanOrEqualTo(1));
  });
}
