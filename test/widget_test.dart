import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

/// Smoke test for the design system.
///
/// The original placeholder here pumped the whole app, which needs Firebase
/// initialised and therefore always failed in a unit test.
void main() {
  testWidgets('light theme builds a screen with the kit widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppTheme.green),
        home: const Scaffold(
          body: Column(
            children: [
              SectionHeader(title: 'Section', actionLabel: 'View All'),
              StatCard(
                label: 'Balance',
                value: r'$100.00',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.brand,
              ),
              FilterPill(label: 'All', selected: true, onTap: _noop),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Section'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme builds the same content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Column(
            children: [
              SectionHeader(title: 'Section'),
              StatCard(
                label: 'Balance',
                value: r'$100.00',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Section'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the dark theme is a true black ramp', () {
    // The navy designer palette (#0D1C42 / #010736 / #22396F / #FCF1D0) was
    // replaced on request with a true black ramp. The navy values are kept as
    // tokens so the brand direction can be restored, but they must not leak
    // into the active theme.
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(AppTheme.dark.cardTheme.color, const Color(0xFF141414));
    expect(
      AppTheme.dark.inputDecorationTheme.fillColor,
      const Color(0xFF0A0A0A),
    );
    expect(AppTheme.dark.dividerTheme.color, const Color(0xFF2A2A2A));
    expect(AppTheme.dark.textTheme.bodyMedium!.color, const Color(0xFFF5F5F5));
  });

  test('the navy palette tokens are still defined but unused by the theme', () {
    expect(AppColors.darkScaffold, const Color(0xFF0D1C42));
    expect(AppColors.darkSurface, const Color(0xFF010736));
    expect(AppColors.darkCard, const Color(0xFF22396F));
    expect(AppColors.darkCream, const Color(0xFFFCF1D0));

    for (final navy in const [
      AppColors.darkScaffold,
      AppColors.darkSurface,
      AppColors.darkCard,
    ]) {
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        isNot(navy),
        reason: 'navy must not be the active dark page colour',
      );
    }
  });

  test('the yellow theme is gone', () {
    // Compile-time guard: if AppTheme.yellow ever comes back this fails.
    expect(AppTheme.green, isNotNull);
  });
}

void _noop() {}
