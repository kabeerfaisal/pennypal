import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/confirm_dialog.dart';

/// Mirrors the suspend confirmation used by the admin user detail screen.
class _SuspendDialogHarness extends StatelessWidget {
  const _SuspendDialogHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Suspend this account?',
                message:
                    'Ali Raza will be signed out and shown a blocked screen. '
                    'Their data is kept and they can appeal from that screen, '
                    'and the appeal arrives in your feedback inbox.',
                confirmLabel: 'Suspend',
                color: AppColors.expense,
                icon: Icons.block_rounded,
                field: const TextField(
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Reason (shown to the user)',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              child: const Text('suspend'),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('suspend'));
    await tester.pumpAndSettle();
  }

  Widget host({required Widget child, Size size = const Size(360, 640)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.light(AppColors.brand),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('suspend dialog fits at every size and text scale', () {
    testWidgets('360x640 at 1.0x text', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const _SuspendDialogHarness());
      await openDialog(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('360x640 at 1.5x text', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const _SuspendDialogHarness(),
        ),
      );
      await openDialog(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('320x480 at 2x text, the reported overflow case', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const _SuspendDialogHarness(),
        ),
      );
      await openDialog(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the reason field and both buttons stay reachable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const _SuspendDialogHarness(),
        ),
      );
      await openDialog(tester);

      // Being on screen is what makes them usable, not merely present.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Suspend'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final screenH = tester.view.physicalSize.height;
      final cancel = tester.getRect(find.text('Cancel'));
      final suspend = tester.getRect(find.text('Suspend'));
      expect(cancel.bottom, lessThanOrEqualTo(screenH));
      expect(suspend.bottom, lessThanOrEqualTo(screenH));
    });

    testWidgets('a very long reason still fits', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.light(AppColors.brand),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => ConfirmDialog.show(
                      context,
                      title: 'Suspend this account?',
                      message: 'x ' * 400,
                      confirmLabel: 'Suspend',
                      color: AppColors.expense,
                      icon: Icons.block_rounded,
                      field: const TextField(maxLines: 4),
                    ),
                    child: const Text('suspend'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await openDialog(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('ConfirmDialog behaviour', () {
    testWidgets('cancel resolves false and closes', (tester) async {
      bool? result;
      await tester.pumpWidget(
        host(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: 'Delete this account?',
                  confirmLabel: 'Delete permanently',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(ConfirmDialog), findsNothing);
    });

    testWidgets('confirm resolves true and closes', (tester) async {
      bool? result;
      await tester.pumpWidget(
        host(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ConfirmDialog.show(
                  context,
                  title: 'Restore access?',
                  confirmLabel: 'Restore access',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore access'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(ConfirmDialog), findsNothing);
    });

    testWidgets('works with no message and no field', (tester) async {
      await tester.pumpWidget(
        host(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ConfirmDialog.show(context, title: 'Sure?'),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Sure?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a field can be typed into', (tester) async {
      await tester.pumpWidget(
        host(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Suspend?',
                field: const TextField(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Spam');
      await tester.pumpAndSettle();
      expect(find.text('Spam'), findsOneWidget);
    });

    testWidgets('works on the black theme', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => ConfirmDialog.show(
                      context,
                      title: 'Suspend this account?',
                      message: 'They will be signed out.',
                      confirmLabel: 'Suspend',
                      icon: Icons.block_rounded,
                      field: const TextField(maxLines: 2),
                    ),
                    child: const Text('suspend'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await openDialog(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
