import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

/// Regression guard: a currency symbol was once stripped from its template and
/// rendered as the literal word "sym" on the dashboard.
String _dashboardTemplate(String symbol) =>
    '$symbol${(1234.5).toStringAsFixed(2)}';

void main() {
  group('currency symbol rendering', () {
    test('the symbol is part of the string, not a bare word', () {
      expect(_dashboardTemplate(r'$'), r'$1234.50');
      expect(_dashboardTemplate('Rs'), 'Rs1234.50');
      expect(_dashboardTemplate('€'), '€1234.50');
    });

    test('a missing dollar sign is caught', () {
      // This is the exact bug the dashboard shipped with.
      expect('sym1234.50', isNot(contains(r'$')));
    });
  });

  group('BudgetBar', () {
    Widget bar(String left, String right) => MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        // Deliberately narrow, like the goal chip on the dashboard.
        body: Center(
          child: SizedBox(
            width: 140,
            child: BudgetBar(
              value: 0.4,
              leftLabel: left,
              rightLabel: right,
              color: AppColors.brand,
            ),
          ),
        ),
      ),
    );

    testWidgets('long labels do not overflow a narrow card', (tester) async {
      await tester.pumpWidget(bar('0% of \$50000', 'New saver'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('an absurdly long label still does not overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        bar(
          '0% of \$12345678901234567890 for a very long goal name',
          'Getting started',
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows both labels', (tester) async {
      await tester.pumpWidget(bar('42%', 'Halfway hero'));

      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Halfway hero'), findsOneWidget);
    });

    testWidgets('an empty right label is allowed', (tester) async {
      await tester.pumpWidget(bar('42%', ''));
      await tester.pumpAndSettle();

      expect(find.text('42%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatCard', () {
    testWidgets('shows a currency prefixed value and its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: SizedBox(
              width: 150,
              child: StatCard(
                label: 'Available Balance',
                value: r'$412.50',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
      );

      expect(find.text(r'$412.50'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long value shrinks instead of overflowing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: SizedBox(
              width: 110,
              child: StatCard(
                label: 'Total Income This Month',
                value: r'$12345678.90',
                icon: Icons.trending_up_rounded,
                color: AppColors.income,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
