import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/success_overlay.dart';

void main() {
  Widget host({required Widget child}) => MaterialApp(
    theme: AppTheme.light(AppColors.brand),
    home: Scaffold(body: Center(child: child)),
  );

  group('SuccessOverlay', () {
    testWidgets('shows the title, subtitle and detail', (tester) async {
      await tester.pumpWidget(
        host(
          child: const SuccessOverlay(
            title: 'Transaction added',
            subtitle: 'Lunch was recorded as an expense.',
            detail: '-Rs250  ·  Food',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transaction added'), findsOneWidget);
      expect(find.text('Lunch was recorded as an expense.'), findsOneWidget);
      expect(find.text('-Rs250  ·  Food'), findsOneWidget);
    });

    testWidgets('the tick is drawn in, not shown instantly', (tester) async {
      await tester.pumpWidget(
        host(
          child: const SuccessOverlay(
            title: 'Account suspended',
            subtitle: 'Ali is now blocked.',
          ),
        ),
      );

      // The circle and the tick arrive together on the same controller.
      expect(find.byType(CustomPaint), findsWidgets);

      // At the start the tick path is not drawn yet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(find.text('Account suspended'), findsOneWidget);
    });

    testWidgets('the action button pops the route', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await SuccessOverlay.show(
                      context,
                      title: 'Transaction added',
                    );
                    popped = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SuccessOverlay), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(SuccessOverlay), findsNothing);
    });

    testWidgets('a custom action label is used', (tester) async {
      await tester.pumpWidget(
        host(
          child: const SuccessOverlay(
            title: 'Account suspended',
            actionLabel: 'Back to users',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back to users'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('subtitle and detail are optional', (tester) async {
      await tester.pumpWidget(
        host(child: const SuccessOverlay(title: 'Saved')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 2x text scaling on a small phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(
            child: const SuccessOverlay(
              title: 'Account suspended successfully',
              subtitle:
                  'Muhammad Hashir Edhi is now blocked from using PennyPal.',
              detail: 'Repeated policy violations',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Account suspended'), findsOneWidget);
    });
  });
}
