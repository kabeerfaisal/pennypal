import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/voice_service.dart';
import 'package:penny_pal/services/voice_unavailable_io.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/pennypal_logo.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

void main() {
  group('the brand mark is one icon everywhere', () {
    testWidgets('the app bar wordmark uses the piggy bank', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(body: PennyPalWordmark()),
        ),
      );
      await tester.pumpAndSettle();

      // The wordmark used to draw a leaf, which is not the splash logo.
      expect(find.byIcon(PennyPalLogo.mark), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsNothing);
      expect(find.text('PennyPal'), findsOneWidget);
    });

    testWidgets('the welcome banner uses the same piggy bank', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: WelcomeBanner(name: 'Ali', role: 'Student'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(PennyPalLogo.mark), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsNothing);
    });

    testWidgets('the mark renders on the black theme too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: PennyPalWordmark()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(PennyPalLogo.mark), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the in-body top bar AI link works', () {
    testWidgets('tapping the robot fires the callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: WelcomeBanner(
              name: 'Ali',
              role: 'Student',
              onTapAi: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // It was a decorative icon before, so nothing happened on tap.
      await tester.tap(find.byIcon(Icons.smart_toy_rounded));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('the chip meets the 44pt minimum tap target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: WelcomeBanner(name: 'Ali', role: 'Student', onTapAi: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ink = tester.getRect(find.byType(InkWell));
      expect(ink.width, greaterThanOrEqualTo(44));
      expect(ink.height, greaterThanOrEqualTo(44));
    });

    testWidgets('tapping the chip anywhere inside it works', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: WelcomeBanner(
              name: 'Ali',
              role: 'Student',
              onTapAi: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ink = tester.getRect(find.byType(InkWell));
      // Four taps across the chip: a glyph-only target would miss three.
      await tester.tapAt(ink.center);
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(ink.left + 3, ink.center.dy));
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(ink.right - 3, ink.center.dy));
      await tester.pumpAndSettle();

      expect(taps, 3);
    });

    testWidgets('no callback means no AI chip at all', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const Scaffold(
            body: WelcomeBanner(name: 'Ali', role: 'Student'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A microphone-less, tappable-looking icon that does nothing is worse
      // than not showing it.
      expect(find.byIcon(Icons.smart_toy_rounded), findsNothing);
    });

    testWidgets('a long name does not push the chip off the card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: WelcomeBanner(
              name: 'Muhammad Hashir Edhi with a very long display name',
              role: 'Administrator',
              onTapAi: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
    });
  });

  group('voice availability', () {
    test('the fallback reports itself unavailable rather than pretending', () {
      final v = SpeechVoiceService();
      expect(v.isAvailable, isFalse);
      expect(v.isListening, isFalse);
      expect(v.lastError, isNotEmpty);
    });

    test('every fallback call is safe', () async {
      final v = VoiceUnavailable();
      await v.init();
      await v.start();
      await v.stop();
      await v.cancel();
      v.dispose();
      expect(v.isAvailable, isFalse);
    });
  });
}
