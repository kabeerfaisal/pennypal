import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/screens/privacy_policy_screen.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/pennypal_logo.dart';

void main() {
  Future<void> host(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(AppColors.brand),
        home: const PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    for (var i = 0; i < 12; i++) {
      if (find.text(text).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        return;
      }
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
    }
  }

  group('the policy says the things people look for', () {
    testWidgets('what is collected comes before what is not', (tester) async {
      await host(tester);

      // The first section is on screen without scrolling.
      expect(find.text('What we collect'), findsOneWidget);
      // The second follows it almost immediately, so one short scroll reaches
      // it. This is what puts the two questions people actually ask at the top
      // of the page rather than buried at the bottom.
      expect(find.text('What we do not collect'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();

      expect(find.text('What we do not collect'), findsOneWidget);
      expect(find.text('What we collect'), findsOneWidget);
    });

    testWidgets('every section is present and reachable', (tester) async {
      await host(tester);

      for (final section in const [
        'What we collect',
        'What we do not collect',
        'Who can see your data',
        'Where your data is stored',
        'The AI advisor',
        'Notifications on your phone',
        'Deleting your account',
        'Your choices',
        'Questions',
      ]) {
        await scrollTo(tester, section);
        expect(
          find.text(section),
          findsOneWidget,
          reason: 'section "$section" must be in the policy',
        );
      }
    });

    testWidgets('it is honest about the AI sending question text', (
      tester,
    ) async {
      await host(tester);
      await scrollTo(tester, 'The AI advisor');

      // A privacy policy that hides the only third party would be worthless.
      expect(find.textContaining('Groq'), findsOneWidget);
    });

    testWidgets('it is honest that there is no remote push service', (
      tester,
    ) async {
      await host(tester);
      await scrollTo(tester, 'Notifications on your phone');

      expect(find.textContaining('do not use a remote push'), findsOneWidget);
    });

    testWidgets('it states the data is never sold or shared', (tester) async {
      await host(tester);
      await scrollTo(tester, 'What we do not collect');

      expect(find.textContaining('do not sell or share'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('uses the app brand mark', (tester) async {
      await host(tester);

      expect(find.byIcon(PennyPalLogo.mark), findsOneWidget);
      expect(find.text('PennyPal Privacy Policy'), findsOneWidget);
    });

    testWidgets('carries a last updated date', (tester) async {
      await host(tester);

      expect(find.textContaining('Last updated'), findsOneWidget);
    });

    testWidgets('renders on the black theme', (tester) async {
      await host(tester, theme: AppTheme.dark);

      expect(find.text('What we collect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on a small phone at 1.5x text', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.5),
          ),
          child: MaterialApp(
            theme: AppTheme.light(AppColors.brand),
            home: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long bullet wraps instead of overflowing', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: AppTheme.light(AppColors.brand),
            home: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
