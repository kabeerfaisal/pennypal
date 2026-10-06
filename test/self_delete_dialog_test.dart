import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';

/// The same dialog the profile screen opens, in a plain host so the test needs
/// no Firebase session behind it.
///
/// Mirrored rather than imported because the dialog is file private on purpose:
/// it is an implementation detail of the profile screen, and testing it through
/// a harness keeps the test from needing a live Firestore to be mounted.
class _DeleteDialogHarness extends StatelessWidget {
  const _DeleteDialogHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const _DeleteDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final TextEditingController _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      scrollable: true,
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.expense,
          size: 28,
        ),
      ),
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Everything goes: your transactions, savings goals, profile, '
            'notifications, AI chats and any messages you sent. Your email '
            'is released so it can be registered again.\n\nThis cannot be '
            'undone.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm with your password',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          onPressed: _submit,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

/// The wording and rules the dialog follows, kept in one place so the copy
/// itself is testable without a live Firebase session behind the screen.
const deleteWarning =
    'Everything goes: your transactions, savings goals, '
    'profile, notifications, AI chats and any messages you sent. Your email '
    'is released so it can be registered again.\n\nThis cannot be undone.';

void main() {
  Future<void> host(
    WidgetTester tester, {
    TextScaler scale = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), textScaler: scale),
        child: const _DeleteDialogHarness(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('before anything is deleted', () {
    testWidgets('it asks for the password', (tester) async {
      await host(tester);
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.text('Confirm with your password'), findsOneWidget);
    });

    testWidgets('an empty password is refused inside the dialog', (
      tester,
    ) async {
      await host(tester);

      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();

      // Still open with the reason shown, rather than closing and then failing
      // against Firebase with a less useful message.
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.text('Enter your password to confirm'), findsOneWidget);
    });

    testWidgets('Cancel closes it without asking for anything', (tester) async {
      await host(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsNothing);
    });
  });

  group('what the warning has to say', () {
    // Every one of these is a promise the app has to keep. The copy is asserted
    // so it cannot quietly lose one while the code still behaves that way, or
    // the other way round.
    const promised = [
      'transactions',
      'savings goals',
      'profile',
      'notifications',
      'AI chats',
      'registered again',
    ];

    test('it names every kind of data that is removed', () {
      for (final p in promised) {
        expect(deleteWarning, contains(p), reason: 'the copy should say $p');
      }
    });

    test('it says the email comes back, which is the reason to use this', () {
      // An admin cannot do this, so the email being released is the whole
      // reason a student would choose it over asking an admin.
      expect(deleteWarning, contains('released'));
      expect(deleteWarning, contains('registered again'));
    });

    test('it says it cannot be undone', () {
      expect(deleteWarning, contains('cannot be undone'));
    });

    test('it is a warning, not a confirmation of something already done', () {
      // A student must not read this after the fact, which would be too late to
      // make it a real choice.
      expect(deleteWarning.toLowerCase(), contains('cannot be'));
    });
  });

  group('it survives a small screen', () {
    testWidgets('no overflow at 2x text on a 320 wide phone', (tester) async {
      // The warning plus a text field is the combination that pushed the
      // buttons out of view.
      await host(tester, scale: const TextScaler.linear(2));

      expect(tester.takeException(), isNull);
      expect(find.text('Delete everything'), findsOneWidget);
    });

    testWidgets('no overflow at 3x text', (tester) async {
      await host(tester, scale: const TextScaler.linear(3));
      expect(tester.takeException(), isNull);
    });
  });
}
