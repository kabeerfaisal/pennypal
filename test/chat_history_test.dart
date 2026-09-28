import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/chat_history_service.dart';

void main() {
  group('ChatMessage', () {
    test('round trips through the Firestore shape', () {
      final m = ChatMessage(
        role: 'user',
        content: 'How much can I spend this week?',
        at: DateTime(2026, 3, 4, 5, 6),
      );
      final map = m.toMap();
      expect(map['Role'], 'user');
      expect(map['Content'], 'How much can I spend this week?');

      final back = ChatMessage.fromFirestore('x', map);
      expect(back.role, 'user');
      expect(back.content, 'How much can I spend this week?');
      expect(back.isUser, isTrue);
    });

    test('an assistant turn is not marked as the user', () {
      final m = ChatMessage.fromFirestore('x', {
        'Role': 'assistant',
        'Content': 'Try cutting one want.',
      });
      expect(m.isUser, isFalse);
    });

    test('a missing role defaults to user rather than throwing', () {
      final m = ChatMessage.fromFirestore('x', {'Content': 'hi'});
      expect(m.isUser, isTrue);
    });

    test('a missing timestamp does not throw', () {
      final m = ChatMessage.fromFirestore('x', {
        'Role': 'user',
        'Content': 'hi',
      });
      expect(m.at, isA<DateTime>());
    });
  });

  group('ChatHistoryService binding', () {
    tearDown(() => ChatHistoryService.instance.reset());

    test('starts with nothing', () {
      expect(ChatHistoryService.instance.messages, isEmpty);
      expect(ChatHistoryService.instance.activeChatId, isNull);
    });

    test('binding to a user clears the previous session', () {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      expect(s.activeChatId, isNull);

      // Signing a different student in on the same device must not inherit it.
      s.bindTo('user-b');
      expect(s.messages, isEmpty);
    });

    test('binding the same user twice keeps the session', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: 'hello');
      s.bindTo('user-a');
      expect(s.messages, hasLength(1));
    });

    test('reset wipes everything, as on sign out', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: 'hello');
      s.reset();
      expect(s.messages, isEmpty);
      expect(s.activeChatId, isNull);
    });
  });

  group('ChatHistoryService in-memory cache', () {
    tearDown(() => ChatHistoryService.instance.reset());

    test('a turn is recorded even with no Firestore available', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: 'first');

      // This is the fallback that keeps the reply visible in the UI even when
      // the write fails or Firebase never initialised.
      expect(s.messages, hasLength(1));
      expect(s.messages.first.content, 'first');
      expect(s.activeChatId, 'c1');
    });

    test('empty turns are ignored', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: '   ');
      expect(s.messages, isEmpty);
    });

    test('the history is trimmed to the cap', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      for (var i = 0; i < ChatHistoryService.maxMessages + 25; i++) {
        await s.append(chatId: 'c1', role: 'user', content: 'q$i');
      }
      expect(s.messages, hasLength(ChatHistoryService.maxMessages));
      // The oldest are dropped, the newest kept.
      expect(
        s.messages.last.content,
        'q${ChatHistoryService.maxMessages + 24}',
      );
    });

    test('turns keep their order', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: 'one');
      await s.append(chatId: 'c1', role: 'assistant', content: 'two');
      await s.append(chatId: 'c1', role: 'user', content: 'three');

      expect(s.messages.map((m) => m.content).toList(), [
        'one',
        'two',
        'three',
      ]);
    });

    test('separate conversations do not bleed into each other', () async {
      final s = ChatHistoryService.instance;
      s.bindTo('user-a');
      await s.append(chatId: 'c1', role: 'user', content: 'chat one');
      await s.append(chatId: 'c2', role: 'user', content: 'chat two');
      await s.load('c1');

      expect(s.messages.single.content, 'chat one');
    });
  });

  group('conversation titles', () {
    test('a short question becomes the title as is', () {
      expect(
        ChatHistoryService.titleFor('How much can I spend?'),
        'How much can I spend?',
      );
    });

    test('a long question is trimmed with an ellipsis', () {
      final t = ChatHistoryService.titleFor('word ' * 30);
      expect(t.length, lessThanOrEqualTo(43));
      expect(t, endsWith('...'));
    });

    test('an empty question still gets a name', () {
      expect(ChatHistoryService.titleFor('   '), 'New chat');
    });

    test('runs of whitespace collapse', () {
      expect(ChatHistoryService.titleFor('a   b\n\nc'), 'a b c');
    });
  });
}
