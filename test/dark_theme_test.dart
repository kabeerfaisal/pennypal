import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

void main() {
  group('dark theme is true black', () {
    test('the scaffold is pure black, not navy', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        isNot(AppColors.darkScaffold),
        reason: 'the navy #0D1C42 palette is no longer used',
      );
    });

    test('cards are raised above the page so they stay separable', () {
      final card = AppTheme.dark.cardTheme.color!;
      final page = AppTheme.dark.scaffoldBackgroundColor;
      expect(card, isNot(page));
      // A card must be lighter than the page, not darker, or it disappears.
      expect(card.computeLuminance(), greaterThan(page.computeLuminance()));
    });

    test('the app bar matches the page, not the card', () {
      expect(
        AppTheme.dark.appBarTheme.backgroundColor,
        AppTheme.dark.scaffoldBackgroundColor,
      );
    });

    test('body text is light on the black background', () {
      final text = AppTheme.dark.textTheme.bodyMedium!;
      expect(
        text.color!.computeLuminance(),
        greaterThan(AppTheme.dark.scaffoldBackgroundColor.computeLuminance()),
      );
    });

    test('input fields are darker than cards so they read as recessed', () {
      final fill = AppTheme.dark.inputDecorationTheme.fillColor!;
      final card = AppTheme.dark.cardTheme.color!;
      expect(fill.computeLuminance(), lessThan(card.computeLuminance()));
    });

    test('borders are visible against the black page', () {
      final line = AppTheme.dark.dividerTheme.color!;
      final page = AppTheme.dark.scaffoldBackgroundColor;
      expect(line.computeLuminance(), greaterThan(page.computeLuminance()));
    });

    test('the FAB is not the default grey', () {
      final fab = AppTheme.dark.floatingActionButtonTheme.backgroundColor;
      expect(fab, AppColors.brand);
    });

    test('the light theme is untouched and still light', () {
      final light = AppTheme.light(AppColors.brand);
      expect(light.brightness, Brightness.light);
      expect(
        light.scaffoldBackgroundColor.computeLuminance(),
        greaterThan(0.5),
      );
    });
  });

  group('SectionHeader corner action', () {
    Widget host({required String? label, VoidCallback? onTap}) => MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: SectionHeader(
          title: 'Savings Goals',
          actionLabel: label,
          onAction: onTap,
        ),
      ),
    );

    testWidgets('the action sits at the trailing edge of the header', (
      tester,
    ) async {
      await tester.pumpWidget(host(label: 'View All', onTap: () {}));
      await tester.pumpAndSettle();

      final title = tester.getRect(find.text('Savings Goals'));
      final action = tester.getRect(find.text('View All'));
      // Same row, and the action is to the right of the title.
      expect((action.left - title.right).abs(), lessThan(title.left + 400));
      expect(action.center.dy, closeTo(title.center.dy, 24));
      expect(action.right, greaterThan(title.right));
    });

    testWidgets('the action is tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(label: 'View All', onTap: () => taps++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('the arrow icon marks it as a link', (tester) async {
      await tester.pumpWidget(host(label: 'View All', onTap: () {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('no action renders when the label is null', (tester) async {
      await tester.pumpWidget(host(label: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('a long action label does not push the title off screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(label: 'View All History Please', onTap: () {}),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Savings Goals'), findsOneWidget);
    });

    testWidgets('survives 2x text scaling', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(label: 'View All', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('is readable on the black theme too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SectionHeader(
              title: 'Savings Goals',
              actionLabel: 'View All',
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View All'), findsOneWidget);
    });
  });
}
