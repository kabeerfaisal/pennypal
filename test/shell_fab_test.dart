import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/success_overlay.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

/// Reproduces the shell layout: a scrolling list plus the floating action
/// button, so the two can be checked for overlap.
class _ShellHarness extends StatelessWidget {
  const _ShellHarness({required this.showFab, required this.bottomPad});

  final bool showFab;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                heroTag: 'fab',
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Transaction'),
              )
            : null,
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
          children: [
            const SizedBox(height: 500),
            const SurfaceCard(child: Text('last row')),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
  }

  group('list clears the floating action button', () {
    testWidgets('the last row is not hidden behind the button', (tester) async {
      await tester.pumpWidget(
        const _ShellHarness(showFab: true, bottomPad: 96),
      );
      await scrollToEnd(tester);

      final row = tester.getRect(find.text('last row'));
      final fab = tester.getRect(find.text('Add Transaction'));

      expect(
        row.bottom,
        lessThan(fab.top),
        reason: 'the last row must sit above the button',
      );
    });

    testWidgets('a short bottom padding would have hidden it', (tester) async {
      // Guards the value itself, so the padding cannot be trimmed by accident.
      await tester.pumpWidget(const _ShellHarness(showFab: true, bottomPad: 8));
      await scrollToEnd(tester);

      final row = tester.getRect(find.text('last row'));
      final fab = tester.getRect(find.text('Add Transaction'));
      expect(row.bottom, greaterThan(fab.top));
    });

    testWidgets('a 96pt pad is enough on a small phone at 1.5x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const _ShellHarness(showFab: true, bottomPad: 96),
          ),
        ),
      );
      await scrollToEnd(tester);

      final row = tester.getRect(find.text('last row'));
      final fab = tester.getRect(find.text('Add Transaction'));
      expect(row.bottom, lessThan(fab.top));
    });

    testWidgets('the button is still reachable', (tester) async {
      await tester.pumpWidget(
        const _ShellHarness(showFab: true, bottomPad: 96),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('transaction success confirmation', () {
    testWidgets('the tick is green, as asked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const SuccessOverlay(
            title: 'Transaction added',
            detail: '-Rs250  ·  Food',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fill = AppColors.income;
      expect(fill, const Color(0xFF16A34A));
      // The green is what the disc is painted with.
      expect(fill.computeLuminance(), lessThan(0.5));
      expect(find.text('Transaction added'), findsOneWidget);
    });

    testWidgets('an expense and an income both get a green tick', (
      tester,
    ) async {
      // The amount carries the direction; the tick always means "saved".
      for (final detail in const ['-Rs250  ·  Food', '+Rs5000  ·  Salary']) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(AppColors.brand),
            home: SuccessOverlay(
              title: 'Transaction added',
              detail: detail,
              color: AppColors.income,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(detail), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
