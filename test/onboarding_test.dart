import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/screens/onboarding_screen.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/pennypal_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The walkthrough writes a "seen" flag, which needs a working store.
  SharedPreferences.setMockInitialValues({});

  Future<void> host(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: OnboardingScreen(onDone: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToLast(WidgetTester tester) async {
    // Walk forward rather than jumping, so the PageView is in a real state.
    for (var i = 0; i < 12; i++) {
      if (find.text('Get started').evaluate().isNotEmpty) break;
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
  }

  group('onboarding first run', () {
    testWidgets('starts on the welcome slide with a Skip escape', (
      tester,
    ) async {
      await host(tester);

      expect(find.text('Welcome to PennyPal'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get started'), findsNothing);
    });

    testWidgets('the first slide uses the piggy bank mark', (tester) async {
      await host(tester);

      expect(find.byIcon(PennyPalLogo.mark), findsWidgets);
    });

    testWidgets('Skip finishes immediately', (tester) async {
      var done = false;
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: OnboardingScreen(onDone: () => done = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });
  });

  group('the "what lives where" guide', () {
    testWidgets('is the last slide and lists every area', (tester) async {
      await host(tester);
      await goToLast(tester);

      expect(find.text('What lives where'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);

      // The list is lazy, so the tail is asserted after a scroll.
      for (final label in const [
        'Dashboard',
        'Transactions',
        'Budget',
        'Savings',
        'Learning',
        'AI advisor',
      ]) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '"$label" must be in the guide',
        );
      }

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      for (final label in const ['Notifications', 'Profile']) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '"$label" must be reachable by scrolling',
        );
      }
    });

    testWidgets('the list scrolls so the last rows are reachable', (
      tester,
    ) async {
      await host(tester);
      await goToLast(tester);

      // Profile is the last row and may start off screen.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('says the AI advisor is on the green bar', (tester) async {
      await host(tester);
      await goToLast(tester);

      expect(
        find.text('Tap the robot on the green bar to ask anything'),
        findsOneWidget,
      );
    });

    testWidgets('finishes with Get started', (tester) async {
      var done = false;
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: OnboardingScreen(onDone: () => done = true),
        ),
      );
      await tester.pumpAndSettle();
      await goToLast(tester);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });
  });

  group('onboarding survives a small screen at large text', () {
    testWidgets('the guide slide does not overflow at 1.5x', (tester) async {
      await host(tester, scale: 1.5);
      await goToLast(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('What lives where'), findsOneWidget);
    });

    testWidgets('a 320x568 screen at 1.5x has no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            theme: AppTheme.light(AppColors.brand),
            home: OnboardingScreen(onDone: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await goToLast(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('works on the black theme', (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: OnboardingScreen(onDone: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await goToLast(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('What lives where'), findsOneWidget);
    });
  });
}
