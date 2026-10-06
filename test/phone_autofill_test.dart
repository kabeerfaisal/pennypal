import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/utils/phone_rule.dart';

/// Mirrors the phone field on the register and profile screens.
class _PhoneHarness extends StatefulWidget {
  const _PhoneHarness();

  @override
  State<_PhoneHarness> createState() => _PhoneHarnessState();
}

class _PhoneHarnessState extends State<_PhoneHarness> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(PhoneRule.max),
            ],
            autofillHints: const <String>[],
            enableSuggestions: false,
            autocorrect: false,
            enableIMEPersonalizedLearning: false,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const _PhoneHarness());
    await tester.pumpAndSettle();
  }

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  group('the phone field does not pull in saved contacts', () {
    testWidgets('uses a plain number keypad, not the phone type', (
      tester,
    ) async {
      await open(tester);

      // TextInputType.phone is what makes Chrome and Android offer the
      // autofill service, which drops the device's whole contact list over the
      // field. That is the "too many numbers" the user was seeing.
      expect(field(tester).keyboardType, TextInputType.number);
      expect(field(tester).keyboardType, isNot(TextInputType.phone));
    });

    testWidgets('declares itself as not an autofill target', (tester) async {
      await open(tester);

      // An empty list, not null: null means "let the platform decide", which
      // is exactly how the dropdown came back.
      expect(field(tester).autofillHints, isNotNull);
      expect(field(tester).autofillHints, isEmpty);
    });

    testWidgets('has suggestions, autocorrect and IME learning off', (
      tester,
    ) async {
      await open(tester);

      expect(field(tester).enableSuggestions, isFalse);
      expect(field(tester).autocorrect, isFalse);
      expect(field(tester).enableIMEPersonalizedLearning, isFalse);
    });
  });

  group('the phone field still works', () {
    testWidgets('accepts digits', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '03001234567');
      await tester.pumpAndSettle();

      expect(_ctrlOf(tester).text, '03001234567');
    });

    testWidgets('still strips letters and symbols', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '03-00 123 4567');
      await tester.pumpAndSettle();

      expect(_ctrlOf(tester).text, '03001234567');
    });

    testWidgets('still stops at the maximum length', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '12345678901234567890');
      await tester.pumpAndSettle();

      expect(_ctrlOf(tester).text.length, PhoneRule.max);
    });

    testWidgets('accepts a short local number', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '0300123');
      await tester.pumpAndSettle();

      expect(PhoneRule.validate(_ctrlOf(tester).text), isNull);
    });
  });
}

/// Reads the controller back out of the field the harness built.
TextEditingController _ctrlOf(WidgetTester tester) {
  final f = tester.widget<TextField>(find.byType(TextField));
  return f.controller!;
}
