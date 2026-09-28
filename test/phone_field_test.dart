import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/utils/phone_rule.dart';

/// Mirrors the register screen's phone field exactly, including the
/// formatters and the live error, so the real behaviour is what gets tested.
/// Owns its own controller so each test starts clean.
class _PhoneFieldHarness extends StatefulWidget {
  const _PhoneFieldHarness();

  @override
  State<_PhoneFieldHarness> createState() => _PhoneFieldHarnessState();
}

class _PhoneFieldHarnessState extends State<_PhoneFieldHarness> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _digits => _ctrl.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final digits = _digits;
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(PhoneRule.max),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Phone number',
              helperText: digits.isEmpty ? PhoneRule.hint : null,
              errorText: digits.isEmpty ? null : PhoneRule.validate(digits),
              suffixIcon: digits.isEmpty
                  ? null
                  : Icon(
                      PhoneRule.isValid(digits)
                          ? Icons.check_circle_rounded
                          : Icons.more_horiz_rounded,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  group('phone field accepts a full 11 digit number', () {
    testWidgets('no error is shown', (tester) async {
      // The old field rejected this and claimed it was too long.
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '03001234567');

      expect(find.textContaining('too long'), findsNothing);
      expect(find.textContaining('cannot be longer'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('phone field accepts a short local number', () {
    testWidgets('seven digits shows the tick and no error', (tester) async {
      // The old field demanded exactly 11 and would not let the user register.
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '0300123');

      expect(find.textContaining('more digit'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('phone field still guides the user while typing', () {
    testWidgets('the shortfall is counted live', (tester) async {
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '030');

      expect(find.textContaining('4 more digits'), findsOneWidget);
      expect(find.textContaining('3/7'), findsOneWidget);
      // Not valid yet, so no tick.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('the hint explains the range before anything is typed', (
      tester,
    ) async {
      await tester.pumpWidget(const _PhoneFieldHarness());

      expect(find.text(PhoneRule.hint), findsOneWidget);
      expect(find.textContaining('exactly 11'), findsNothing);
    });

    testWidgets('letters and symbols are stripped, not rejected', (
      tester,
    ) async {
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '03-00 123 4567');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '03001234567');
    });

    testWidgets('typing stops at the maximum', (tester) async {
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '12345678901234567890');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, PhoneRule.max);
    });

    testWidgets('an over-long paste never reaches the field', (tester) async {
      // This is the case the double length limiter used to fight over.
      await tester.pumpWidget(const _PhoneFieldHarness());
      await type(tester, '1234567890123456789012345');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, PhoneRule.max);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('phone field at 2x text scaling', () {
    testWidgets('does not overflow on a small phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _PhoneFieldHarness(),
        ),
      );
      await type(tester, '0300');

      expect(tester.takeException(), isNull);
    });
  });
}
