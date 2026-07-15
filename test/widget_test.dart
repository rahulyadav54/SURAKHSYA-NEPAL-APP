import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_nepal/main.dart';

void main() {
  testWidgets('Splash Screen renders and redirects to Onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TickerMode(
          enabled: false,
          child: SurakshaNepalApp(),
        ),
      ),
    );

    // 1. Verify Splash Screen elements render initially
    expect(find.text('सुरक्षा नेपाल'), findsOneWidget);
    expect(find.text('Loading system elements...'), findsOneWidget);

    // 2. Advance timer by 2.5 seconds to trigger the navigation forward transition
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // 3. Verify Onboarding Screen renders successfully after redirection
    expect(find.text('एकिकृत आपतकालीन सेवा'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
