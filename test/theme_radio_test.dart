import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the Appearance section of the profile screen: two rows inside one
/// RadioGroup. This guards the rewrite that replaced the deprecated per-Radio
/// `groupValue` / `onChanged` with a single ancestor. Wiring it wrongly leaves
/// two independent radios, so tapping one no longer updates the other.
class _ThemeRows extends StatefulWidget {
  const _ThemeRows();

  @override
  State<_ThemeRows> createState() => _ThemeRowsState();
}

class _ThemeRowsState extends State<_ThemeRows> {
  String _theme = 'Green';
  final List<String> _calls = [];

  void _select(String value) => setState(() {
    _theme = value;
    _calls.add(value);
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: RadioGroup<String>(
          groupValue: _theme,
          onChanged: (v) {
            if (v != null) _select(v);
          },
          child: Column(
            children: [
              ListTile(
                title: const Text('Green Theme'),
                trailing: const Radio<String>(value: 'Green'),
                onTap: () => _select('Green'),
              ),
              ListTile(
                title: const Text('Dark Theme'),
                trailing: const Radio<String>(value: 'Dark'),
                onTap: () => _select('Dark'),
              ),
              Text('state=$_theme calls=$_calls'),
            ],
          ),
        ),
      ),
    );
  }
}

Radio<String> _radio(WidgetTester tester, String value) =>
    tester.widget<Radio<String>>(
      find.byWidgetPredicate((w) => w is Radio<String> && w.value == value),
    );

void main() {
  testWidgets('neither radio carries its own groupValue or onChanged', (
    tester,
  ) async {
    // If either one does, they stop being a single group and the second
    // control becomes independent of the first.
    await tester.pumpWidget(const _ThemeRows());
    await tester.pumpAndSettle();

    // The deprecated members are read on purpose: that they are null is the
    // whole point of the assertion.
    // ignore: deprecated_member_use
    expect(_radio(tester, 'Green').groupValue, isNull);
    // ignore: deprecated_member_use
    expect(_radio(tester, 'Green').onChanged, isNull);
    // ignore: deprecated_member_use
    expect(_radio(tester, 'Dark').groupValue, isNull);
    // ignore: deprecated_member_use
    expect(_radio(tester, 'Dark').onChanged, isNull);
  });

  testWidgets('tapping Dark selects Dark', (tester) async {
    await tester.pumpWidget(const _ThemeRows());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();

    expect(find.text('state=Dark calls=[Dark]'), findsOneWidget);
  });

  testWidgets('the whole row is the tap target, not just the radio', (
    tester,
  ) async {
    await tester.pumpWidget(const _ThemeRows());
    await tester.pumpAndSettle();

    // The tap is on the title, well away from the radio.
    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();

    expect(find.textContaining('state=Dark'), findsOneWidget);
  });

  testWidgets('tapping the radio itself also switches', (tester) async {
    await tester.pumpWidget(const _ThemeRows());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Radio<String>).last);
    await tester.pumpAndSettle();

    expect(find.text('state=Dark calls=[Dark]'), findsOneWidget);
  });

  testWidgets('switching back and forth keeps them in sync', (tester) async {
    await tester.pumpWidget(const _ThemeRows());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Green Theme'));
    await tester.pumpAndSettle();

    expect(find.text('state=Green calls=[Dark, Green]'), findsOneWidget);
  });
}
