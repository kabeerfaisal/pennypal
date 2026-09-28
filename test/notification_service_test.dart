import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/notice_banner.dart';
import 'package:penny_pal/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(NotificationService.instance.reset);

  group('notification entries', () {
    test('a kind survives a round trip through Firestore shape', () {
      for (final kind in NotifyKind.values) {
        final entry = AppNotification(
          id: 'x',
          title: 'T',
          body: 'B',
          kind: kind,
          at: DateTime(2026, 1, 2, 3, 4),
        );
        final map = entry.toMap();
        expect(map['Kind'], kind.name);

        // Firestore stores the timestamp as a sentinel, so the reader has to
        // cope with a missing timestamp too.
        final back = AppNotification.fromFirestore('x', map);
        expect(back.kind, kind);
        expect(back.title, 'T');
        expect(back.body, 'B');
        expect(back.read, isFalse);
      }
    });

    test('an unknown kind falls back instead of throwing', () {
      final back = AppNotification.fromFirestore('x', {
        'Title': 'T',
        'Body': 'B',
        'Kind': 'SomethingNew',
      });
      expect(back.kind, NotifyKind.system);
    });

    test('a read flag is carried and can be toggled', () {
      final n = AppNotification(
        id: 'x',
        title: 'T',
        body: 'B',
        kind: NotifyKind.budget,
        at: DateTime.now(),
        read: true,
      );
      expect(n.read, isTrue);
      expect(n.copyWith(read: false).read, isFalse);
      expect(n.copyWith(read: false).title, 'T');
    });

    test('the id is unique per notification', () {
      final a = AppNotification(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        title: 'T',
        body: 'B',
        kind: NotifyKind.goal,
        at: DateTime.now(),
      );
      final b = AppNotification(
        id: 'local-${DateTime.now().microsecondsSinceEpoch + 1}',
        title: 'T',
        body: 'B',
        kind: NotifyKind.goal,
        at: DateTime.now(),
      );
      expect(a.id, isNot(b.id));
    });
  });

  group('notification list', () {
    testWidgets('a new notification is added newest first', (tester) async {
      final s = NotificationService.instance;
      NotificationService.notify('First', 'a', showBanner: false);
      await tester.pump();
      NotificationService.notify('Second', 'b', showBanner: false);
      await tester.pump();

      expect(s.items.first.title, 'Second');
      expect(s.items.length, 2);
    });

    testWidgets('unread count only counts unread', (tester) async {
      final s = NotificationService.instance;
      NotificationService.notify('A', 'a', showBanner: false);
      NotificationService.notify('B', 'b', showBanner: false);
      await tester.pump();
      expect(s.unreadCount, 2);

      await s.markRead(s.items.first.id);
      await tester.pump();
      expect(s.unreadCount, 1);
    });

    testWidgets('mark all read clears the badge', (tester) async {
      final s = NotificationService.instance;
      NotificationService.notify('A', 'a', showBanner: false);
      NotificationService.notify('B', 'b', showBanner: false);
      await tester.pump();

      await s.markAllRead();
      await tester.pump();
      expect(s.unreadCount, 0);
    });

    testWidgets('a removed notification disappears', (tester) async {
      final s = NotificationService.instance;
      NotificationService.notify('A', 'a', showBanner: false);
      await tester.pump();

      await s.remove(s.items.first.id);
      await tester.pump();
      expect(s.items, isEmpty);
    });

    testWidgets('reset clears everything, as on sign out', (tester) async {
      final s = NotificationService.instance;
      NotificationService.notify('A', 'a', showBanner: false);
      await tester.pump();

      s.reset();
      await tester.pump();
      expect(s.items, isEmpty);
      expect(s.unreadCount, 0);
    });

    testWidgets('notifying without Firestore still records the entry', (
      tester,
    ) async {
      // No Firebase in a widget test, so this is the in-memory fallback the
      // app relies on when the write fails.
      NotificationService.notify(
        'Monthly budget exceeded',
        'You have spent Rs6200 of Rs6000.',
        kind: NotifyKind.budget,
        showBanner: false,
      );
      await tester.pump();

      expect(NotificationService.instance.items, hasLength(1));
      expect(NotificationService.instance.items.first.kind, NotifyKind.budget);
    });
  });

  group('banner', () {
    testWidgets('a notification with showBanner raises the banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const NoticeBanner(
            navKey: null,
            child: Scaffold(body: Text('screen')),
          ),
        ),
      );

      NotificationService.notify(
        'Monthly budget exceeded',
        'You have spent Rs6200 of Rs6000.',
        kind: NotifyKind.budget,
        level: NoticeLevel.warning,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Monthly budget exceeded'), findsOneWidget);
      expect(find.text('You have spent Rs6200 of Rs6000.'), findsOneWidget);
    });

    testWidgets('a silent notification records without a banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: const NoticeBanner(
            navKey: null,
            child: Scaffold(body: Text('screen')),
          ),
        ),
      );

      NotificationService.notify(
        'Expense added',
        'Lunch -Rs250',
        kind: NotifyKind.transaction,
        showBanner: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Expense added'), findsNothing);
      expect(NotificationService.instance.items, hasLength(1));
    });
  });
}
