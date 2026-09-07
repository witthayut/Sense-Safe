// Smoke test: the app boots and lands on the login screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:haptic_drive/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HapticDriveApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Haptic Drive'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
