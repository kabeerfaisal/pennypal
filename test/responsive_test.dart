import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

/// Renders [child] at a given device size and text scale, returning the
/// overflow exception if one happened.
Future<Object?> _render(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  double textScale = 1.0,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
  return tester.takeException();
}

/// Smallest phone still worth supporting, plus a large one.
const small = Size(320, 568);
const medium = Size(390, 844);
const large = Size(430, 932);

const _threeStats = Row(
  children: [
    Expanded(
      child: StatCard(
        label: 'Available Balance',
        value: r'$412.50',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.brand,
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: StatCard(
        label: 'Monthly Spent',
        value: r'$645.00',
        icon: Icons.trending_down_rounded,
        color: AppColors.expense,
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: StatCard(
        label: 'Total Income',
        value: r'$1200.00',
        icon: Icons.trending_up_rounded,
        color: AppColors.income,
      ),
    ),
  ],
);

void main() {
  group('dashboard stat row', () {
    testWidgets('fits a small phone', (tester) async {
      expect(await _render(tester, child: _threeStats, size: small), isNull);
    });

    testWidgets('fits a small phone at 1.5x text', (tester) async {
      expect(
        await _render(tester, child: _threeStats, size: small, textScale: 1.5),
        isNull,
      );
    });

    testWidgets('fits a small phone at 2x text', (tester) async {
      expect(
        await _render(tester, child: _threeStats, size: small, textScale: 2.0),
        isNull,
      );
    });

    testWidgets('fits a large phone', (tester) async {
      expect(await _render(tester, child: _threeStats, size: large), isNull);
    });
  });

  group('section headers', () {
    final header = Column(
      children: const [
        SectionHeader(title: 'Savings Goals', actionLabel: 'View All'),
        SizedBox(height: 8),
        SectionHeader(
          title: 'Expenses by Category',
          actionLabel: 'All History',
        ),
      ],
    );

    testWidgets('title and action never collide on a small phone', (
      tester,
    ) async {
      expect(await _render(tester, child: header, size: small), isNull);
    });

    testWidgets('survives 2x text', (tester) async {
      expect(
        await _render(tester, child: header, size: small, textScale: 2.0),
        isNull,
      );
    });
  });

  group('ProgressRing', () {
    Widget ring(String value, {String badge = '65% used'}) => Center(
      child: ProgressRing(
        value: 0.645,
        size: 178,
        centerValue: value,
        caption: 'spent this month',
        badge: badge,
      ),
    );

    testWidgets('a long currency value stays inside the circle', (
      tester,
    ) async {
      // This is the dashboard symptom: "$1,234 / $2,000" spilling outside.
      expect(
        await _render(tester, child: ring(r'$1,234 / $2,000'), size: small),
        isNull,
      );
    });

    testWidgets('a very long value does not overflow', (tester) async {
      expect(
        await _render(
          tester,
          child: ring(r'$1234567.89 / $9876543.21'),
          size: small,
        ),
        isNull,
      );
    });

    testWidgets('a long badge does not overflow', (tester) async {
      expect(
        await _render(
          tester,
          child: ring(r'$40 / $2000', badge: 'Getting started this month'),
          size: small,
        ),
        isNull,
      );
    });

    testWidgets('survives 2x text', (tester) async {
      expect(
        await _render(
          tester,
          child: ring(r'$40 / $2000'),
          size: small,
          textScale: 2.0,
        ),
        isNull,
      );
    });

    testWidgets('works with no badge', (tester) async {
      expect(
        await _render(
          tester,
          child: ring(r'$0 / $0', badge: ''),
          size: medium,
        ),
        isNull,
      );
    });

    /// No exception is thrown when text spills past the ring, so the geometry
    /// is asserted directly.
    testWidgets('the value text sits inside the ring, not across the stroke', (
      tester,
    ) async {
      const ringSize = 178.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: Center(
              child: ProgressRing(
                value: 0.31,
                size: ringSize,
                centerValue: 'Rs6200 / Rs20000',
                caption: 'spent this month',
                badge: '31% used',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textRect = tester.getRect(find.text('Rs6200 / Rs20000'));
      final ringRect = tester.getRect(find.byType(ProgressRing));
      // The stroke is 7.5% of the size and sits inside the box, so the text
      // must be narrower than the ring minus the stroke.
      final stroke = ringSize * 0.075;
      final allowed = ringRect.width - stroke * 2;

      expect(
        textRect.width,
        lessThan(allowed),
        reason: 'text ${textRect.width} must be narrower than $allowed',
      );
      // And vertically it must not reach the stroke either.
      expect(textRect.top, greaterThan(ringRect.top + stroke));
      expect(textRect.bottom, lessThan(ringRect.bottom - stroke));
    });

    testWidgets('also fits a small 150pt ring', (tester) async {
      const smallRing = 150.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: Center(
              child: ProgressRing(
                value: 0.31,
                size: smallRing,
                centerValue: 'Rs6200 / Rs20000',
                caption: 'spent this month',
                badge: '31% used',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textRect = tester.getRect(find.text('Rs6200 / Rs20000'));
      final ringRect = tester.getRect(find.byType(ProgressRing));
      final allowed = ringRect.width - smallRing * 0.075 * 2;

      expect(textRect.width, lessThan(allowed));
      expect(tester.takeException(), isNull);
    });
  });

  group('result strip', () {
    testWidgets('stays on one line with long numbers', (tester) async {
      final strip = const ResultStrip(
        count: 1234,
        totalLabel: 'Net total',
        totalValue: r'-$12345678.90',
      );
      expect(await _render(tester, child: strip, size: small), isNull);
    });
  });

  group('dark theme', () {
    testWidgets('stat row renders without error', (tester) async {
      tester.view
        ..physicalSize = small
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: _threeStats),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
