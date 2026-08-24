import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/onboarding_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';

void main() {
  testWidgets('Get Started replaces onboarding with HomeScreen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Report shows the photo selection counter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportRescueScreen()));

    expect(find.text('0 / 5 photos selected'), findsOneWidget);
  });

  testWidgets('Submit button shows confirmation feedback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportRescueScreen()));

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.textContaining('Report submitted'), findsOneWidget);
  });
}
