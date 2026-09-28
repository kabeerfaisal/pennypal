import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/widgets/notice_banner.dart';

void main() {
  testWidgets('shows nothing until a notice is sent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('screen'), findsOneWidget);
  });

  testWidgets('renders the title and body of a notice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    NoticeBanner.show('Goal complete', 'Laptop is fully funded. Well done.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Goal complete'), findsOneWidget);
    expect(find.text('Laptop is fully funded. Well done.'), findsOneWidget);
    // It is a banner under the app bar, not a bottom SnackBar.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('close button dismisses it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    NoticeBanner.show('Spending warning', 'Food is at 85% of its limit.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Spending warning'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Spending warning'), findsNothing);
  });

  testWidgets('auto dismisses after the timeout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    NoticeBanner.show('Savings milestone', 'Emergency Fund is halfway there.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Savings milestone'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Savings milestone'), findsNothing);
  });

  testWidgets('a new notice replaces the current one', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    NoticeBanner.show('Spending warning', 'Food is at 85% of its limit.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    NoticeBanner.show('Spending limit hit', 'Food is at its monthly limit.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Spending limit hit'), findsOneWidget);
    expect(find.text('Spending warning'), findsNothing);
  });

  testWidgets('level picks a different icon and colour', (tester) async {
    Future<void> show(NoticeLevel level) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoticeBanner(
            navKey: null,
            child: Scaffold(body: Text('screen')),
          ),
        ),
      );
      NoticeBanner.show('Title', 'Body', level: level);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await show(NoticeLevel.success);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await show(NoticeLevel.warning);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await show(NoticeLevel.info);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);
  });

  testWidgets('child still fills the remaining space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );

    final size = tester.getSize(find.byType(NoticeBanner));
    expect(size.height, greaterThan(300));
  });

  testWidgets('picks up a notice that fired before the banner mounted', (
    tester,
  ) async {
    // Can happen while the app is still on the splash screen.
    NoticeBanner.show('Goal complete', 'Laptop is fully funded.');

    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Goal complete'), findsOneWidget);
  });

  testWidgets('ignores a stale notice older than the timeout', (tester) async {
    // Shrink the window so the retained notice is already older than it.
    NoticeBanner.displayDuration = const Duration(milliseconds: 1);
    addTearDown(
      () => NoticeBanner.displayDuration = const Duration(seconds: 7),
    );

    NoticeBanner.show('Old news', 'This should not appear.');
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(navKey: null, child: Scaffold(body: Text('screen'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Old news'), findsNothing);
  });

  testWidgets('banner sits above the page content, not at the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoticeBanner(
          navKey: null,
          child: Scaffold(body: SizedBox(height: 900, child: Text('screen'))),
        ),
      ),
    );

    NoticeBanner.show('Savings milestone', 'Emergency Fund is halfway there.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final bannerY = tester.getTopLeft(find.text('Savings milestone')).dy;
    final contentY = tester.getTopLeft(find.text('screen')).dy;
    // Content gets pushed down rather than being covered.
    expect(bannerY, lessThan(contentY));
  });

  testWidgets('survives a widget rebuild without crashing', (tester) async {
    Widget build(String label) => MaterialApp(
      home: NoticeBanner(navKey: null, child: Scaffold(body: Text(label))),
    );

    await tester.pumpWidget(build('one'));
    NoticeBanner.show('Goal complete', 'Nicely done.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(build('two'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
