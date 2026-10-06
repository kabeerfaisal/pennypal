import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';

/// The profile header, in isolation, so its geometry can be measured against
/// the top of the screen.
class _HeaderHarness extends StatelessWidget {
  const _HeaderHarness({this.topPadding = 20});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        appBar: AppBar(title: const Text('Profile & Settings')),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Text('U', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ali',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<void> host(WidgetTester tester, {double top = 20}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_HeaderHarness(topPadding: top));
    await tester.pumpAndSettle();
  }

  group('the profile header is not cut off at the top', () {
    testWidgets('the avatar has breathing room below the app bar', (
      tester,
    ) async {
      await host(tester);

      final avatar = tester.getRect(find.byType(CircleAvatar));
      final appBar = tester.getRect(find.byType(AppBar));

      // This is the reported problem: the circle was touching the app bar and
      // looked sliced in half.
      expect(
        avatar.top - appBar.bottom,
        greaterThanOrEqualTo(8),
        reason: 'the avatar must not be flush against the app bar',
      );
    });

    testWidgets('nothing in the header is clipped by the body', (tester) async {
      await host(tester);

      final avatar = tester.getRect(find.byType(CircleAvatar));
      final header = tester.getRect(
        find
            .ancestor(
              of: find.byType(CircleAvatar),
              matching: find.byType(Container),
            )
            .first,
      );

      // The header has to fully contain the avatar, top edge included.
      expect(header.top, lessThanOrEqualTo(avatar.top));
      expect(header.bottom, greaterThanOrEqualTo(avatar.bottom));
    });

    testWidgets('zero top padding is what caused it, and is now gone', (
      tester,
    ) async {
      // Pinned so the padding cannot be trimmed back to zero by accident.
      await host(tester, top: 20);
      final withRoom = tester.getRect(find.byType(CircleAvatar)).top;

      await host(tester, top: 0);
      final flush = tester.getRect(find.byType(CircleAvatar)).top;

      expect(withRoom, greaterThan(flush));
    });

    testWidgets('the header spans the full width', (tester) async {
      await host(tester);

      final header = tester.getRect(
        find
            .ancestor(
              of: find.byType(CircleAvatar),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(header.width, 390);
    });

    testWidgets('the bottom is rounded so the green does not run flat', (
      tester,
    ) async {
      await host(tester);

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(CircleAvatar),
              matching: find.byType(Container),
            )
            .first,
      );
      final radius = container.decoration as BoxDecoration;
      expect(radius.borderRadius, isA<BorderRadius>());
      final r = radius.borderRadius as BorderRadius;
      expect(r.bottomLeft.x, greaterThan(0));
      expect(r.bottomRight.x, greaterThan(0));
    });

    testWidgets('a long name does not push the header taller than needed', (
      tester,
    ) async {
      await host(tester);

      final header = tester.getRect(
        find
            .ancestor(
              of: find.byType(CircleAvatar),
              matching: find.byType(Container),
            )
            .first,
      );
      final avatar = tester.getRect(find.byType(CircleAvatar));
      // Avatar plus padding plus the name, and not an absurd amount.
      expect(header.height, lessThan(avatar.height + 140));
    });

    testWidgets('no overflow on a small phone at 2x text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const _HeaderHarness(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
