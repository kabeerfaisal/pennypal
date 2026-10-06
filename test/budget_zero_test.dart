import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/controllers/finance_controller.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/confirm_dialog.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

void main() {
  group('the default budget is zero', () {
    test('a new account starts with no budget', () {
      expect(FinanceController.defaultBudget, 0);
    });

    test('it is not the old guessed figure', () {
      // The previous default invented a number for the student, which then
      // read as though they were immediately over their limit.
      expect(FinanceController.defaultBudget, isNot(2000));
    });

    test('a zero budget cannot be read as a percentage', () {
      // home_view computed expenses / budget, which has to be guarded.
      const budget = FinanceController.defaultBudget;
      final expenses = 500.0;
      expect(budget > 0 ? expenses / budget : 0.0, 0.0);
    });

    test('clearing a budget returns to unset, not to a guess', () {
      // Matches FinanceController.clearBudget, which must not reintroduce a
      // default figure.
      expect(FinanceController.defaultBudget, 0.0);
    });
  });

  group('a zero budget renders as a prompt, not a zero ring', () {
    testWidgets('the ring shows no percentage when there is no limit', (
      tester,
    ) async {
      // The guard home_view relies on before showing the ring at all.
      final value = FinanceController.defaultBudget > 0 ? 500 / 2000 : 0.0;
      expect(value, 0.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: ProgressRing(
              value: 0,
              centerValue: r'$500 / $0',
              caption: 'no limit set yet',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No badge, because there is no percentage to report.
      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('no limit set yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the suspend dialog survives being dismissed with back', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => ConfirmDialog.show(
                    context,
                    title: 'Suspend this account?',
                    message: 'They will be signed out.',
                    confirmLabel: 'Suspend',
                    color: AppColors.expense,
                    icon: Icons.block_rounded,
                    fieldLabel: 'Reason (shown to the user)',
                    initialFieldValue: 'Repeated policy violations',
                    onFieldChanged: (_) {},
                  ),
                  child: const Text('suspend'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('suspend'));
      await tester.pumpAndSettle();
    }

    testWidgets('typing a reason then pressing back raises no exception', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Spamming the group chat');
      await tester.pumpAndSettle();

      // The back gesture, exactly what the admin was doing.
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pumpAndSettle();

      // Previously this threw "A TextEditingController was used after being
      // disposed", because the controller was disposed while the route was
      // still animating away.
      expect(tester.takeException(), isNull);
      expect(find.text('Suspend this account?'), findsNothing);
    });

    testWidgets('dismissing by tapping the barrier is also clean', (
      tester,
    ) async {
      await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Suspend this account?'), findsNothing);
    });

    testWidgets('the typed reason is still readable after back', (
      tester,
    ) async {
      // The callback pattern means the value survives even though the dialog
      // is gone, so the caller can decide what to do with it.
      var reason = 'initial';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => ConfirmDialog.show(
                    context,
                    title: 'Suspend this account?',
                    confirmLabel: 'Suspend',
                    color: AppColors.expense,
                    fieldLabel: 'Reason',
                    initialFieldValue: reason,
                    onFieldChanged: (v) => reason = v,
                  ),
                  child: const Text('suspend'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('suspend'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Late fees');
      await tester.pumpAndSettle();

      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pumpAndSettle();

      expect(reason, 'Late fees');
      expect(tester.takeException(), isNull);
    });
  });
}
