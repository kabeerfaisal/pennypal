import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/app_tour.dart';
import 'package:penny_pal/widgets/guided_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps a screen with a button that asks for the walkthrough, the way the
/// dashboard's `initState` does.
Future<void> pumpLauncher(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => AppTour.maybeShow(
                context,
                locate: (_) => null,
                steps: buildTourSteps(),
              ),
              child: const Text('launch'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTour.resetForTest();
  });

  tearDown(AppTour.resetForTest);

  group('only ever one walkthrough at a time', () {
    testWidgets('two requests in the same frame show one, not two', (
      tester,
    ) async {
      // This is the reported bug. The dashboard's initState can run twice while
      // a student is signing in, and both runs asked for a tour. Because the
      // preference check is an await, both got past it and both inserted.
      await pumpLauncher(tester);

      final ctx = tester.element(find.text('launch'));
      AppTour.maybeShow(ctx, locate: (_) => null, steps: buildTourSteps());
      AppTour.maybeShow(ctx, locate: (_) => null, steps: buildTourSteps());
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(GuidedTour),
        findsOneWidget,
        reason: 'a second request must not stack a second walkthrough',
      );
      expect(AppTour.activeCount, 1);
    });

    testWidgets('three requests still show one', (tester) async {
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      for (var i = 0; i < 3; i++) {
        AppTour.maybeShow(ctx, locate: (_) => null, steps: buildTourSteps());
      }
      await tester.pump();
      await tester.pump();

      expect(find.byType(GuidedTour), findsOneWidget);
      expect(AppTour.activeCount, 1);
    });

    testWidgets('the step counter belongs to a single walkthrough', (
      tester,
    ) async {
      // Two cards each counting independently is what made the screenshots read
      // "1 of 7" and "4 of 7" at the same time.
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      AppTour.maybeShow(ctx, locate: (_) => null, steps: buildTourSteps());
      AppTour.maybeShow(ctx, locate: (_) => null, steps: buildTourSteps());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('of 7'), findsOneWidget);
      expect(find.text('1 of 7'), findsOneWidget);
    });

    testWidgets('a request after finishing does not bring it back', (
      tester,
    ) async {
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      await AppTour.maybeShow(
        ctx,
        locate: (_) => null,
        steps: buildTourSteps(),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(GuidedTour), findsOneWidget);

      // Tap through to the end, or skip, whichever is one tap away.
      await tester.tap(find.text('Skip tour').first);
      await tester.pump();
      await tester.pump();
      expect(find.byType(GuidedTour), findsNothing);
      expect(AppTour.activeCount, 0);

      // And the preference is written, so a later request is ignored.
      expect(await AppTour.hasSeen(), isTrue);
      await AppTour.maybeShow(
        ctx,
        locate: (_) => null,
        steps: buildTourSteps(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(GuidedTour), findsNothing);
    });
  });

  group('the slot is never left stuck', () {
    testWidgets('tearing the route down mid-tour lets it run again', (
      tester,
    ) async {
      // Pressing the system back button pops the route under the overlay, which
      // removes the entry without the finish handler ever running. If the slot
      // stayed claimed, the walkthrough would be gone for good.
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      await AppTour.maybeShow(
        ctx,
        locate: (_) => null,
        steps: buildTourSteps(),
      );
      await tester.pump();
      await tester.pump();
      expect(AppTour.activeCount, 1);

      // Rebuild the tree, which is what destroys the overlay and its entries.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('x'))),
      );
      await tester.pump();

      AppTour.maybeShow(
        tester.element(find.text('x')),
        locate: (_) => null,
        steps: buildTourSteps(),
      );
      await tester.pump();
      await tester.pump();

      expect(
        AppTour.activeCount,
        1,
        reason: 'a stale slot must be reclaimed, not kept forever',
      );
    });
  });

  group('already-seen students', () {
    testWidgets('nothing is shown and no slot is claimed', (tester) async {
      SharedPreferences.setMockInitialValues({AppTour.prefKey: true});
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      await AppTour.maybeShow(
        ctx,
        locate: (_) => null,
        steps: buildTourSteps(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(GuidedTour), findsNothing);
      expect(AppTour.activeCount, 0);
    });

    testWidgets('an empty step list is a no-op', (tester) async {
      await pumpLauncher(tester);
      final ctx = tester.element(find.text('launch'));

      await AppTour.maybeShow(ctx, locate: (_) => null, steps: const []);
      await tester.pump();

      expect(AppTour.activeCount, 0);
      expect(find.byType(GuidedTour), findsNothing);
    });
  });
}
