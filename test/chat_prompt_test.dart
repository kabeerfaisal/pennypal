import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/utils/chat_prompt.dart';

void main() {
  const snapshot =
      'Currency USD. Monthly budget \$2000. This month spent \$645, income '
      '\$1200, remaining \$1355. Category spend: Food: \$240. Goals: Laptop 120/800.';

  group('ChatPrompt.isSmallTalk', () {
    test('treats bare greetings as small talk', () {
      for (final q in [
        'hello',
        'Hello',
        'hi',
        'hey',
        'yo',
        'good morning',
        'how are you',
        'salam',
        'assalam o alaikum',
        'thanks',
        'bye',
        'testing',
      ]) {
        expect(ChatPrompt.isSmallTalk(q), isTrue, reason: q);
      }
    });

    test('tolerates punctuation and spacing', () {
      expect(ChatPrompt.isSmallTalk('  hello!  '), isTrue);
      expect(ChatPrompt.isSmallTalk('hi there'), isTrue);
      expect(ChatPrompt.isSmallTalk('Hello!!'), isTrue);
    });

    test('does NOT treat a real question as small talk', () {
      for (final q in [
        'how much did I spend on food',
        'what is my budget',
        'can I afford a laptop',
        'tell me about my savings goal',
        'hello, what is my remaining budget?',
        'hi, suggest a savings plan',
        'why is my spending high?',
      ]) {
        expect(ChatPrompt.isSmallTalk(q), isFalse, reason: q);
      }
    });
  });

  group('ChatPrompt.isFinanceRelated', () {
    test('detects money questions', () {
      for (final q in [
        'how much did I spend',
        'what is my budget',
        'can I afford it',
        'help me save money',
        'my goal progress',
        'check my expenses',
        'what is left',
        'I have 500 left, enough?',
      ]) {
        expect(ChatPrompt.isFinanceRelated(q), isTrue, reason: q);
      }
    });

    test('unrelated questions do not pull in the numbers', () {
      for (final q in [
        'hello',
        'what is the capital of France',
        'write me a poem',
        'who are you',
        'thanks',
      ]) {
        expect(ChatPrompt.isFinanceRelated(q), isFalse, reason: q);
      }
    });
  });

  group('ChatPrompt.build', () {
    test('omits the finance snapshot for unrelated questions', () {
      final prompt = ChatPrompt.build(
        question: 'write me a poem about rain',
        snapshot: snapshot,
      );

      // No numbers means nothing for the model to volunteer.
      expect(prompt, isNot(contains('2000')));
      expect(prompt, isNot(contains('645')));
      expect(prompt, isNot(contains(snapshot)));
      expect(prompt, contains('write me a poem about rain'));
    });

    test('includes the snapshot for money questions', () {
      final prompt = ChatPrompt.build(
        question: 'how much did I spend on food?',
        snapshot: snapshot,
      );

      expect(prompt, contains(snapshot));
      expect(prompt, contains('how much did I spend on food?'));
    });

    test('always forbids volunteering extra advice', () {
      final prompt = ChatPrompt.build(
        question: 'what is 2+2',
        snapshot: snapshot,
      );

      expect(prompt, contains('Answer ONLY the question that was asked'));
      expect(prompt, contains('Never volunteer the budget'));
      expect(prompt, contains('Never invent amounts'));
      expect(prompt.toLowerCase(), contains('one to three sentences'));
      // Closing instruction reinforces the point for a reasoning model.
      expect(prompt.trimRight(), endsWith('Answer that question only.'));
    });

    test(
      'keeps instructions in the user turn, as Groq advises for GPT-OSS',
      () {
        final prompt = ChatPrompt.build(
          question: 'my budget?',
          snapshot: snapshot,
        );
        expect(prompt, contains('You are PennyPal AI'));
      },
    );
  });

  group('ChatPrompt.smallTalkReply', () {
    test('never mentions budget or figures', () {
      for (final q in ['hello', 'hi', 'hey', 'thanks', 'bye', 'how are you']) {
        final reply = ChatPrompt.smallTalkReply(q).toLowerCase();
        expect(reply, isNot(contains('budget')), reason: q);
        expect(reply, isNot(contains('spent')));
        expect(reply, isNot(contains('\$')));
      }
    });

    test('stays short, one or two sentences', () {
      for (final q in ['hello', 'thanks', 'bye', 'how are you']) {
        expect(
          ChatPrompt.smallTalkReply(q).split(RegExp(r'[.!?]')).length,
          lessThanOrEqualTo(3),
          reason: q,
        );
      }
    });
  });
}
