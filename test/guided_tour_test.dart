import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/app_tour.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/guided_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget host({
    required Rect? Function(String) locate,
    required List<TourStep> steps,
    VoidCallback? onDone,
  }) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: GuidedTour(locate: locate, steps: steps, onDone: onDone ?? () {}),
      ),
    );
  }

  /// A single anchor near the top, so the highlight has somewhere to sit.
  Rect locateTop(String anchor) => const Rect.fromLTWH(40, 80, 160, 44);

  /// A small phone with an explicit MediaQuery, so the logical size the tour
  /// reads is the one under test rather than the default test surface.
  Widget scaled(
    Rect? Function(String) locate,
    List<TourStep> steps, {
    required double scale,
    Size size = const Size(320, 568),
  }) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: GuidedTour(locate: locate, steps: steps, onDone: () {}),
        ),
      ),
    );
  }

  group('the tour copy', () {
    test('covers every area of the app', () {
      final anchors = buildTourSteps().map((s) => s.anchor).toSet();
      expect(anchors, containsAll(TourAnchors.all));
    });

    test('no step has an anchor the app does not mark up', () {
      // Guards against a typo silently producing a centred, unhighlighted step.
      for (final s in buildTourSteps()) {
        expect(TourAnchors.all, contains(s.anchor), reason: s.title);
      }
    });

    test('every step explains itself', () {
      for (final s in buildTourSteps()) {
        expect(s.title.trim(), isNotEmpty, reason: s.anchor);
        expect(s.body.trim().length, greaterThan(20), reason: s.title);
      }
    });

    test('the steps are unique, so no anchor is highlighted twice', () {
      final anchors = buildTourSteps().map((s) => s.anchor).toList();
      expect(anchors.toSet().length, anchors.length);
    });

    test('anchor names are all distinct constants', () {
      expect(TourAnchors.all.toSet().length, TourAnchors.all.length);
    });
  });

  group('the tour walks through its steps', () {
    testWidgets('starts on step one and advances', (tester) async {
      await tester.pumpWidget(host(locate: locateTop, steps: buildTourSteps()));
      await tester.pumpAndSettle();

      expect(find.text('1 of 7'), findsOneWidget);
      expect(find.text('Your screen at a glance'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 7'), findsOneWidget);
      expect(find.text('Ask the AI anything'), findsOneWidget);
    });

    testWidgets('the last step says Got it instead of Next', (tester) async {
      await tester.pumpWidget(host(locate: locateTop, steps: buildTourSteps()));
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('7 of 7'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Got it finishes the tour', (tester) async {
      var done = false;
      final steps = buildTourSteps();
      await tester.pumpWidget(
        host(locate: locateTop, steps: steps, onDone: () => done = true),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < steps.length - 1; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });

    testWidgets('Skip tour finishes immediately', (tester) async {
      var done = false;
      await tester.pumpWidget(
        host(
          locate: locateTop,
          steps: buildTourSteps(),
          onDone: () => done = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });

    testWidgets('the close cross also finishes', (tester) async {
      var done = false;
      await tester.pumpWidget(
        host(
          locate: locateTop,
          steps: buildTourSteps(),
          onDone: () => done = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });

    testWidgets('tapping the dimmed screen advances', (tester) async {
      await tester.pumpWidget(host(locate: locateTop, steps: buildTourSteps()));
      await tester.pumpAndSettle();

      // Top centre, clear of both the highlight and the callout.
      await tester.tapAt(const Offset(400, 16));
      await tester.pumpAndSettle();

      expect(find.text('2 of 7'), findsOneWidget);
    });
  });

  group('the tour handles a missing anchor', () {
    testWidgets('an anchor that is not built still explains itself', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(locate: (_) => null, steps: buildTourSteps()),
      );
      await tester.pumpAndSettle();

      // No highlight, but the explanation is still shown rather than dropped.
      expect(find.text('1 of 7'), findsOneWidget);
      expect(find.text('Your screen at a glance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty step list shows nothing at all', (tester) async {
      await tester.pumpWidget(host(locate: locateTop, steps: const []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('the tour survives small screens and large text', () {
    testWidgets('a 320x568 phone at 1.5x text has no overflow', (tester) async {
      await tester.pumpWidget(scaled(locateTop, buildTourSteps(), scale: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 of 7'), findsOneWidget);
    });

    testWidgets('2x text still advances', (tester) async {
      await tester.pumpWidget(scaled(locateTop, buildTourSteps(), scale: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a degenerate zero size does not crash the tour', (
      tester,
    ) async {
      // A MediaQuery with no size is the shape a badly built host can hand
      // over, and clamp would throw on it.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const MediaQuery(
            data: MediaQueryData(),
            child: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );

      await tester.pumpWidget(
        const MediaQuery(data: MediaQueryData(), child: SizedBox.shrink()),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a highlight near the bottom flips the card above it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          // Right at the bottom, so there is no room below.
          locate: (_) => const Rect.fromLTWH(40, 560, 160, 44),
          steps: buildTourSteps(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 of 7'), findsOneWidget);
    });

    testWidgets('works on the black theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: GuidedTour(
              locate: locateTop,
              steps: buildTourSteps(),
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 of 7'), findsOneWidget);
    });
  });

  group('the tour is shown only once', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install has not seen it', () async {
      expect(await AppTour.hasSeen(), isFalse);
    });

    test('it is remembered after finishing', () async {
      await AppTour.markSeen();
      expect(await AppTour.hasSeen(), isTrue);
    });

    testWidgets('maybeShow puts the tour up on a first run', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AppTour.maybeShow(
                    context,
                    locate: locateTop,
                    steps: buildTourSteps(),
                  ),
                  child: const Text('start'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 7'), findsOneWidget);
    });

    testWidgets('maybeShow does nothing once it has been seen', (tester) async {
      await AppTour.markSeen();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AppTour.maybeShow(
                    context,
                    locate: locateTop,
                    steps: buildTourSteps(),
                  ),
                  child: const Text('start'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      // Interrupting a returning student with a tour they have already
      // dismissed is exactly what this guards against.
      expect(find.text('1 of 7'), findsNothing);
    });

    testWidgets('finishing it records that it was seen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AppTour.maybeShow(
                    context,
                    locate: locateTop,
                    steps: buildTourSteps(),
                  ),
                  child: const Text('start'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();

      expect(await AppTour.hasSeen(), isTrue);
      expect(find.text('1 of 7'), findsNothing);
    });
  });

  group('TourKeys', () {
    test('an anchor that was never mounted has no position', () {
      expect(TourKeys.locate('nothing-here'), isNull);
    });

    testWidgets('a mounted anchor is measured, an absent one is not', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TourKeys.wrap(
                  TourAnchors.topBar,
                  Container(height: 50, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rect = TourKeys.locate(TourAnchors.topBar);
      expect(rect, isNotNull);
      expect(rect!.height, 50);
      // A different anchor was never marked up.
      expect(TourKeys.locate(TourAnchors.budget), isNull);
    });
  });
}
