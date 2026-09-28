import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

void main() {
  Widget host({String? label, String title = 'Savings Goals'}) => MaterialApp(
    theme: AppTheme.light(AppColors.brand),
    home: Scaffold(
      body: SectionHeader(title: title, actionLabel: label, onAction: () {}),
    ),
  );

  group('SectionHeader action is pinned to one side', () {
    testWidgets('its right edge lines up with the row end, not the middle', (
      tester,
    ) async {
      await tester.pumpWidget(host(label: 'View All'));
      await tester.pumpAndSettle();

      final header = tester.getRect(find.byType(SectionHeader));
      final title = tester.getRect(find.text('Savings Goals'));
      final action = tester.getRect(find.text('View All'));

      // The action must finish at the row's right edge, within the padding the
      // parent gives it. Anywhere near the horizontal centre is the bug.
      final centre = header.center.dx;
      expect(
        action.center.dx,
        greaterThan(centre),
        reason: 'the action must sit to the right of the centre',
      );
      expect(
        action.right,
        closeTo(header.right, 40),
        reason: 'the action must be pinned to the trailing edge',
      );
      // And it must not be left of the title.
      expect(action.left, greaterThan(title.left));
    });

    testWidgets('every label length stays on the trailing side', (
      tester,
    ) async {
      for (final label in const [
        'View All',
        'All History',
        'View Budget',
        'View',
        'View All Transactions',
      ]) {
        await tester.pumpWidget(host(label: label));
        await tester.pumpAndSettle();

        final header = tester.getRect(find.byType(SectionHeader));
        final action = tester.getRect(find.text(label));
        expect(action.center.dx, greaterThan(header.center.dx), reason: label);
        expect(tester.takeException(), isNull, reason: label);
      }
    });

    testWidgets('a two line title does not drag the action to the middle', (
      tester,
    ) async {
      // A long title wraps to two lines; the action must stay right-aligned
      // rather than being pushed to the middle of the taller row.
      await tester.pumpWidget(
        host(label: 'View All', title: 'Expenses by Category This Month'),
      );
      await tester.pumpAndSettle();

      final header = tester.getRect(find.byType(SectionHeader));
      final action = tester.getRect(find.text('View All'));
      expect(action.center.dx, greaterThan(header.center.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the action is vertically aligned with the first title line', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(label: 'View All', title: 'Expenses by Category This Month'),
      );
      await tester.pumpAndSettle();

      final title = tester.getRect(
        find.text('Expenses by Category This Month'),
      );
      final action = tester.getRect(find.text('View All'));
      // Centred on the two line title is fine; the complaint was horizontal.
      expect(action.center.dy, closeTo(title.center.dy, 40));
    });

    testWidgets('no action means nothing to align', (tester) async {
      await tester.pumpWidget(host(label: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.text('Savings Goals'), findsOneWidget);
    });

    testWidgets('stays on the trailing side at 2x text on a narrow phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(label: 'View All', title: 'Expenses by Category'),
        ),
      );
      await tester.pumpAndSettle();

      final header = tester.getRect(find.byType(SectionHeader));
      final action = tester.getRect(find.text('View All'));
      expect(action.center.dx, greaterThan(header.center.dx));
      expect(tester.takeException(), isNull);
    });
  });
}
